package hu.dncs.tracker.idempotency.api.web;

import hu.dncs.tracker.idempotency.application.usecase.ExecuteIdempotentRequestUseCase;
import hu.dncs.tracker.idempotency.domain.model.ProcessedRequestId;
import hu.dncs.tracker.idempotency.domain.model.StoredResponse;
import hu.dncs.tracker.identity.api.UserLookup;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.core.ResolvableType;
import org.springframework.http.HttpHeaders;
import org.springframework.http.InvalidMediaTypeException;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter;
import org.springframework.web.util.ContentCachingResponseWrapper;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.InputStreamReader;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

import static org.springframework.http.HttpStatus.CONTENT_TOO_LARGE;

/**
 * Wraps the normal MVC invocation, including validation and response serialization, in one transaction.
 */
final class IdempotentRequestMappingHandlerAdapter extends RequestMappingHandlerAdapter {
    private static final int MAX_REQUEST_BYTES = 1024 * 1024;
    private static final Set<String> MUTATIONS = Set.of("POST", "PUT", "PATCH", "DELETE");
    private static final Set<String> REPRESENTATION_HEADERS = Set.of(
            HttpHeaders.CONTENT_TYPE, HttpHeaders.CONTENT_LENGTH, HttpHeaders.LOCATION, HttpHeaders.ETAG);
    private final ExecuteIdempotentRequestUseCase executor;
    private final ObjectMapper mapper;
    private final UserLookup users;

    IdempotentRequestMappingHandlerAdapter(ExecuteIdempotentRequestUseCase executor, ObjectMapper mapper,
                                           UserLookup users) {
        this.executor = executor;
        this.mapper = mapper;
        this.users = users;
    }

    @Override
    protected ModelAndView handleInternal(HttpServletRequest request, HttpServletResponse response,
                                          HandlerMethod handler) throws Exception {
        var annotation = handler.getMethodAnnotation(Idempotent.class);
        if (annotation == null) {
            return super.handleInternal(request, response, handler);
        }
        checkContract(request, handler, annotation);
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken) {
            throw new AuthenticationCredentialsNotFoundException("An authenticated account is required.");
        }
        var accountId = UUID.fromString(authentication.getName());
        if (!users.userExists(accountId)) {
            throw new AuthenticationCredentialsNotFoundException("The authenticated account is no longer available.");
        }
        var key = parseKey(request);
        byte[] body = request.getInputStream().readNBytes(MAX_REQUEST_BYTES + 1);
        if (body.length > MAX_REQUEST_BYTES) {
            throw new ResponseStatusException(CONTENT_TOO_LARGE, "Idempotent JSON requests are limited to 1 MiB.");
        }
        var bufferedRequest = new BufferedRequest(request, body);
        var bufferedResponse = new ContentCachingResponseWrapper(response);
        response.setHeader(HttpHeaders.CACHE_CONTROL, "no-store");
        StoredResponse result;
        try {
            result = executor.execute(new ProcessedRequestId(accountId, key), annotation.value(),
                    fingerprint(request, body), () -> {
                        var view = super.handleInternal(bufferedRequest, bufferedResponse, handler);
                        if (view != null || request.isAsyncStarted()) {
                            throw new IllegalStateException("@Idempotent requires a synchronous REST response.");
                        }
                        return new StoredResponse(bufferedResponse.getStatus(), bufferedResponse.getContentType(),
                                bufferedResponse.getHeader(HttpHeaders.LOCATION),
                                bufferedResponse.getHeader(HttpHeaders.ETAG), bufferedResponse.getContentAsByteArray());
                    });
        } catch (Exception exception) {
            // Serialization or commit can fail after MVC has already set successful representation headers.
            response.resetBuffer();
            response.setStatus(HttpServletResponse.SC_OK);
            REPRESENTATION_HEADERS.forEach(header -> response.setHeader(header, null));
            throw exception;
        }
        // The transaction has committed before any response bytes are sent. A lost response is safe to retry.
        response.setStatus(result.status());
        response.setContentType(result.contentType());
        response.setHeader(HttpHeaders.LOCATION, result.location());
        response.setHeader(HttpHeaders.ETAG, result.etag());
        response.setContentLength(result.body().length);
        response.getOutputStream().write(result.body());
        return null;
    }

    private UUID parseKey(HttpServletRequest request) {
        var keys = Collections.list(request.getHeaders("Idempotency-Key"));
        if (keys.size() == 1 && keys.getFirst().matches(
                "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")) {
            return UUID.fromString(keys.getFirst());
        }
        throw new InvalidIdempotencyRequestException("Exactly one canonical UUID Idempotency-Key is required.");
    }

    private void checkContract(HttpServletRequest request, HandlerMethod handler, Idempotent annotation) {
        var responseType = ResolvableType.forMethodReturnType(handler.getMethod());
        var bodyType = responseType.getGeneric(0).resolve();
        if (annotation.value().isBlank() || annotation.value().length() > 100
                || !MUTATIONS.contains(request.getMethod())
                || responseType.resolve() != ResponseEntity.class || bodyType == null
                || bodyType == Object.class || isStreamingType(bodyType)) {
            throw new IllegalStateException("@Idempotent requires a named mutation returning ResponseEntity<DTO> or ResponseEntity<Void>.");
        }
        for (var parameter : handler.getMethod().getParameterTypes()) {
            if (ServletResponse.class.isAssignableFrom(parameter) || java.io.OutputStream.class.isAssignableFrom(parameter)
                    || java.io.Writer.class.isAssignableFrom(parameter)) {
                throw new IllegalStateException("@Idempotent endpoints must return their response instead of writing it directly.");
            }
        }
    }

    private boolean isStreamingType(Class<?> type) {
        return org.springframework.core.io.Resource.class.isAssignableFrom(type)
                || org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody.class.isAssignableFrom(type)
                || org.springframework.web.servlet.mvc.method.annotation.ResponseBodyEmitter.class.isAssignableFrom(type)
                || java.io.InputStream.class.isAssignableFrom(type)
                || java.util.concurrent.Future.class.isAssignableFrom(type)
                || java.util.concurrent.CompletionStage.class.isAssignableFrom(type);
    }

    private String fingerprint(HttpServletRequest request, byte[] body) throws Exception {
        var digest = MessageDigest.getInstance("SHA-256");
        for (String part : new String[]{request.getMethod(), request.getRequestURI(), request.getQueryString(),
                request.getContentType(), headers(request, HttpHeaders.ACCEPT), headers(request, HttpHeaders.ACCEPT_LANGUAGE),
                headers(request, HttpHeaders.IF_MATCH), headers(request, HttpHeaders.IF_UNMODIFIED_SINCE)}) {
            update(digest, part == null ? new byte[0] : part.getBytes(StandardCharsets.UTF_8));
        }
        if (body.length > 0) {
            var contentType = request.getContentType();
            try {
                if (contentType == null || !(MediaType.APPLICATION_JSON.isCompatibleWith(MediaType.parseMediaType(contentType))
                        || MediaType.parseMediaType("application/*+json").isCompatibleWith(MediaType.parseMediaType(contentType)))) {
                    throw new InvalidIdempotencyRequestException("Idempotent request bodies must use a JSON Content-Type.");
                }
            } catch (InvalidMediaTypeException exception) {
                throw new InvalidIdempotencyRequestException("Idempotent request bodies must use a valid JSON Content-Type.");
            }
            try {
                update(digest, mapper.writeValueAsBytes(canonical(mapper.readTree(body))));
            } catch (JacksonException exception) {
                throw new InvalidIdempotencyRequestException("The request body must contain valid JSON.");
            }
        } else {
            update(digest, body);
        }
        return HexFormat.of().formatHex(digest.digest());
    }

    private String headers(HttpServletRequest request, String name) {
        return String.join(",", Collections.list(request.getHeaders(name)));
    }

    private Object canonical(JsonNode node) {
        if (node.isObject()) {
            var sorted = new TreeMap<String, Object>();
            node.properties().forEach(entry -> sorted.put(entry.getKey(), canonical(entry.getValue())));
            return sorted;
        }
        if (node.isArray()) {
            var ordered = new ArrayList<Object>();
            node.forEach(value -> ordered.add(canonical(value)));
            return ordered;
        }
        return node;
    }

    private void update(MessageDigest digest, byte[] value) {
        digest.update(ByteBuffer.allocate(Integer.BYTES).putInt(value.length).array());
        digest.update(value);
    }

    private static final class BufferedRequest extends HttpServletRequestWrapper {
        private final ServletInputStream input;

        BufferedRequest(HttpServletRequest request, byte[] body) {
            super(request);
            var bytes = new ByteArrayInputStream(body);
            input = new ServletInputStream() {
                @Override
                public int read() {
                    return bytes.read();
                }

                @Override
                public int read(byte[] target, int offset, int length) {
                    return bytes.read(target, offset, length);
                }

                @Override
                public boolean isFinished() {
                    return bytes.available() == 0;
                }

                @Override
                public boolean isReady() {
                    return true;
                }

                @Override
                public void setReadListener(ReadListener listener) {
                    throw new IllegalStateException("@Idempotent does not support asynchronous request processing.");
                }
            };
        }

        @Override
        public ServletInputStream getInputStream() {
            return input;
        }

        @Override
        public BufferedReader getReader() {
            return new BufferedReader(new InputStreamReader(input, StandardCharsets.UTF_8));
        }

        @Override
        public boolean isAsyncSupported() {
            return false;
        }
    }
}
