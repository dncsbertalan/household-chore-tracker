package hu.dncs.tracker.idempotency.api.web;

import hu.dncs.tracker.idempotency.application.usecase.ExecuteIdempotentRequestUseCase;
import hu.dncs.tracker.identity.api.UserDirectory;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.webmvc.autoconfigure.WebMvcRegistrations;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter;
import tools.jackson.databind.ObjectMapper;

@Configuration(proxyBeanMethods = false)
@RequiredArgsConstructor
class IdempotencyWebConfiguration implements WebMvcRegistrations {
    private final ExecuteIdempotentRequestUseCase executor;
    private final ObjectMapper objectMapper;
    private final UserDirectory users;

    @Override
    public RequestMappingHandlerAdapter getRequestMappingHandlerAdapter() {
        return new IdempotentRequestMappingHandlerAdapter(executor, objectMapper, users);
    }
}
