package hu.dncs.tracker;

import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRepository;
import hu.dncs.tracker.idempotency.api.web.Idempotent;
import hu.dncs.tracker.identity.api.web.CurrentUserId;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestComponent;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.net.URI;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import({TestcontainersConfiguration.class, IdempotencyIntegrationTests.Mutations.class,
        IdempotencyIntegrationTests.Failures.class})
class IdempotencyIntegrationTests {
    private static final String PATH = "/_test/idempotency";
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired UserRepository users;
    @Autowired HouseholdRepository households;
    @Autowired Mutations mutations;
    private UUID account;

    @BeforeEach
    void setUp() {
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS idempotency_test_effect (
                    id UUID PRIMARY KEY, name TEXT NOT NULL,
                    account_id UUID NOT NULL REFERENCES users(user_id) DEFERRABLE INITIALLY DEFERRED
                )
                """);
        jdbc.update("DELETE FROM idempotency_test_effect");
        jdbc.update("DELETE FROM processed_request");
        account = newAccount();
        mutations.calls.set(0);
        mutations.failNext.set(false);
        mutations.failSerializationNext.set(false);
        mutations.failCommitNext.set(false);
        mutations.errorResponseNext.set(false);
        mutations.entered = null;
        mutations.release = null;
    }

    @Test
    void replaysExactResponseAndDoesNotRunControllerAgain() throws Exception {
        var key = UUID.randomUUID();
        var body = body(UUID.randomUUID(), "original");
        var original = send(account, key.toString(), body);
        jdbc.update("UPDATE idempotency_test_effect SET name = 'changed later'");
        var replay = send(account, key.toString().toUpperCase(), body);

        assertSameSuccess(original, replay);
        assertThat(mutations.calls.get()).isEqualTo(1);
        assertThat(receipts()).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT name FROM idempotency_test_effect", String.class)).isEqualTo("changed later");
    }

    @Test
    void canonicalizesJsonObjectOrderAndWhitespaceIncludingNestedObjects() throws Exception {
        var key = UUID.randomUUID().toString();
        var id = UUID.randomUUID();
        var original = send(account, key, """
                {"id":"%s", "name":"home", "extra":{"b":2,"a":1}}
                """.formatted(id));
        var replay = send(account, key, """
                { "extra": {"a":1, "b":2}, "name": "home", "id": "%s" }
                """.formatted(id));
        assertSameSuccess(original, replay);
        assertThat(mutations.calls.get()).isEqualTo(1);
    }

    @Test
    void changedPayloadAndArrayOrderConflictWithoutOverwritingReceipt() throws Exception {
        var key = UUID.randomUUID().toString();
        var id = UUID.randomUUID();
        var originalBody = body(id, "original").replace("}", ",\"extra\":[1,2]}");
        var original = send(account, key, originalBody);
        assertThat(send(account, key, body(id, "changed")).getResponse().getStatus()).isEqualTo(409);
        assertThat(send(account, key, originalBody.replace("[1,2]", "[2,1]")).getResponse().getStatus()).isEqualTo(409);
        assertSameSuccess(original, send(account, key, originalBody));
        assertThat(mutations.calls.get()).isEqualTo(1);
    }

    @Test
    void representationAndPreconditionHeadersCannotChangeUnderTheSameKey() throws Exception {
        var key = UUID.randomUUID().toString();
        var body = body(UUID.randomUUID(), "home");
        var original = send(account, key, body);
        for (var header : Map.of("Accept", "application/json", "Accept-Language", "hu",
                "If-Match", "\"new-version\"", "If-Unmodified-Since", "Mon, 26 Oct 2026 12:00:00 GMT").entrySet()) {
            mvc.perform(post(PATH).with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                            .header("Idempotency-Key", key).header(header.getKey(), header.getValue())
                            .contentType(APPLICATION_JSON).content(body))
                    .andExpect(status().isConflict());
        }
        assertSameSuccess(original, send(account, key, body));
        assertThat(mutations.calls.get()).isEqualTo(1);
    }

    @Test
    void rejectsNonJsonAndOversizedRequestsWithoutClaimingTheKey() throws Exception {
        var key = UUID.randomUUID().toString();
        var body = body(UUID.randomUUID(), "home");
        mvc.perform(post(PATH).with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", key).contentType("text/plain").content(body))
                .andExpect(status().isBadRequest());
        mvc.perform(post(PATH).with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(" ".repeat(1024 * 1024 + 1)))
                .andExpect(status().isContentTooLarge());
        assertThat(receipts()).isZero();
        assertThat(mutations.calls.get()).isZero();
        assertThat(send(account, key, body).getResponse().getStatus()).isEqualTo(201);
    }

    @Test
    void operationPathMethodAndQueryArePartOfTheRequestIdentity() throws Exception {
        var key = UUID.randomUUID().toString();
        var body = body(UUID.randomUUID(), "home");
        send(account, key, body);
        mvc.perform(post(PATH + "/other").with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(body))
                .andExpect(status().isConflict());
        mvc.perform(post(PATH + "?mode=other").with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(body))
                .andExpect(status().isConflict());
        mvc.perform(delete(PATH + "/" + UUID.randomUUID()).with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", key)).andExpect(status().isConflict());
        assertThat(mutations.calls.get()).isEqualTo(1);
    }

    @Test
    void keysAreIsolatedBetweenAccounts() throws Exception {
        var key = UUID.randomUUID().toString();
        var first = send(account, key, body(UUID.randomUUID(), "first"));
        var otherAccount = newAccount();
        var secondBody = body(UUID.randomUUID(), "second");
        var second = send(otherAccount, key, secondBody);
        assertThat(first.getResponse().getStatus()).isEqualTo(201);
        assertSameSuccess(second, send(otherAccount, key, secondBody));
        assertThat(mutations.calls.get()).isEqualTo(2);
        assertThat(effects()).isEqualTo(2);
        assertThat(receipts()).isEqualTo(2);
    }

    @Test
    void rejectsMissingMalformedAndMultipleKeysBeforeMutation() throws Exception {
        var body = body(UUID.randomUUID(), "home");
        mvc.perform(post(PATH).with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                .contentType(APPLICATION_JSON).content(body)).andExpect(status().isBadRequest());
        for (String key : new String[]{"", "invalid", "1-1-1-1-1", " " + UUID.randomUUID()}) {
            assertThat(send(account, key, body).getResponse().getStatus()).isEqualTo(400);
        }
        mvc.perform(post(PATH).with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", UUID.randomUUID(), UUID.randomUUID())
                        .contentType(APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
        assertThat(mutations.calls.get()).isZero();
        assertThat(receipts()).isZero();
    }

    @Test
    void authenticationAndAccountExistenceAreCheckedEvenForReplay() throws Exception {
        var key = UUID.randomUUID().toString();
        var body = body(UUID.randomUUID(), "home");
        send(account, key, body);
        mvc.perform(post(PATH).header("Authorization", "Bearer invalid").header("Idempotency-Key", key)
                .contentType(APPLICATION_JSON).content(body)).andExpect(status().isUnauthorized());
        assertThat(send(UUID.randomUUID(), key, body).getResponse().getStatus()).isEqualTo(401);
        assertThat(mutations.calls.get()).isEqualTo(1);
        assertThat(receipts()).isEqualTo(1);
    }

    @Test
    void validationAndMalformedJsonReleaseKeyForCorrectedRequest() throws Exception {
        var key = UUID.randomUUID().toString();
        var id = UUID.randomUUID();
        assertThat(send(account, key, "{").getResponse().getStatus()).isEqualTo(400);
        assertThat(send(account, key, body(id, "")).getResponse().getStatus()).isEqualTo(400);
        assertThat(receipts()).isZero();
        assertThat(send(account, key, body(id, "corrected")).getResponse().getStatus()).isEqualTo(201);
        assertThat(effects()).isEqualTo(1);
    }

    @Test
    void exceptionsAfterDatabaseWritesRollBackMutationAndReceipt() throws Exception {
        mutations.failNext.set(true);
        assertFailureThenRetry();
    }

    @Test
    void serializationFailureRollsBackMutationAndReceipt() throws Exception {
        mutations.failSerializationNext.set(true);
        assertFailureThenRetry();
    }

    @Test
    void commitFailureRollsBackMutationAndReceiptBeforeSendingSuccess() throws Exception {
        mutations.failCommitNext.set(true);
        assertFailureThenRetry();
    }

    @Test
    void receiptPersistenceFailureAlsoRollsBackBusinessWrites() throws Exception {
        // NOT VALID applies the constraint to new writes without requiring old rows to match it.
        jdbc.execute("ALTER TABLE processed_request ADD CONSTRAINT test_receipt_failure CHECK (response_status IS NULL) NOT VALID");
        try {
            var key = UUID.randomUUID().toString();
            var body = body(UUID.randomUUID(), "home");
            assertThat(send(account, key, body).getResponse().getStatus()).isEqualTo(500);
            assertThat(effects()).isZero();
            assertThat(receipts()).isZero();
        } finally {
            jdbc.execute("ALTER TABLE processed_request DROP CONSTRAINT test_receipt_failure");
        }
    }

    @Test
    void explicitNonSuccessResponseRollsBackAndIsNotCached() throws Exception {
        mutations.errorResponseNext.set(true);
        var key = UUID.randomUUID().toString();
        var body = body(UUID.randomUUID(), "home");
        assertThat(send(account, key, body).getResponse().getStatus()).isEqualTo(422);
        assertThat(effects()).isZero();
        assertThat(receipts()).isZero();
        assertThat(send(account, key, body).getResponse().getStatus()).isEqualTo(201);
        assertThat(effects()).isEqualTo(1);
    }

    @Test
    void replaysNoContentResponsesOnAnotherAnnotatedEndpoint() throws Exception {
        var key = UUID.randomUUID();
        var path = PATH + "/" + UUID.randomUUID();
        for (int attempt = 0; attempt < 2; attempt++) {
            mvc.perform(delete(path).with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                            .header("Idempotency-Key", key)).andExpect(status().isNoContent());
        }
        assertThat(mutations.calls.get()).isEqualTo(1);
        assertThat(receipts()).isEqualTo(1);
    }

    @Test
    void concurrentDuplicateWaitsThenReplaysAfterCommit() throws Exception {
        concurrentRequests(false);
    }

    @Test
    void concurrentDuplicateAcquiresClaimAfterFirstTransactionRollsBack() throws Exception {
        concurrentRequests(true);
    }

    @Test
    void realHouseholdControllerOnlyNeedsTheAnnotation() throws Exception {
        var id = UUID.randomUUID();
        var roleId = UUID.randomUUID();
        var body = """
                {"householdId":"%s", "name":"Home", "description":null,
                 "roles":[{"householdRoleId":"%s", "name":"Admin", "permissions":["HOUSEHOLD_MEMBER_VIEW"]}],
                 "creatorRoleId":"%s", "householdMemberId":"%s"}
                """.formatted(id, roleId, roleId, UUID.randomUUID());
        var key = UUID.randomUUID();
        var original = mvc.perform(post("/api/v1/households").with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(body))
                .andExpect(status().isCreated()).andReturn();
        var replay = mvc.perform(post("/api/v1/households").with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(body))
                .andExpect(status().isCreated()).andReturn();
        assertSameSuccess(original, replay);
        assertThat(households.findById(id)).isPresent();
        assertThat(receipts()).isEqualTo(1);
    }

    @Test
    void nonAnnotatedEndpointsKeepTheirNormalBehavior() throws Exception {
        mvc.perform(get("/api/v1/users/me").with(jwt().jwt(jwt -> jwt.subject(account.toString()))))
                .andExpect(status().isOk());
        assertThat(receipts()).isZero();
    }

    @Test
    void plainDtoWithResponseStatusReplaysTheExactResponse() throws Exception {
        var key = UUID.randomUUID();
        var payload = body(UUID.randomUUID(), "plain response");
        var original = sendPlain(key, payload);
        assertSameSuccess(original, sendPlain(key, payload));
        assertThat(mutations.calls.get()).isEqualTo(1);
        assertThat(effects()).isEqualTo(1);
        assertThat(receipts()).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT account_id FROM idempotency_test_effect", UUID.class)).isEqualTo(account);
    }

    @Test
    void voidWithResponseStatusReplaysAnEmpty204WithoutRepeatingTheMutation() throws Exception {
        var id = UUID.randomUUID();
        send(account, UUID.randomUUID().toString(), body(id, "delete me"));
        var key = UUID.randomUUID();
        for (int attempt = 0; attempt < 2; attempt++) {
            mvc.perform(delete(PATH + "/plain/" + id).with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                            .header("Idempotency-Key", key))
                    .andExpect(status().isNoContent());
        }
        assertThat(mutations.calls.get()).isEqualTo(2);
        assertThat(effects()).isZero();
        assertThat(receipts()).isEqualTo(2);
    }

    @ParameterizedTest
    @ValueSource(strings = {"application", "serialization"})
    void plainDtoFailuresRollBackAndAllowRetry(String failure) throws Exception {
        if (failure.equals("application")) {
            mutations.failNext.set(true);
        } else {
            mutations.failSerializationNext.set(true);
        }
        var key = UUID.randomUUID();
        var payload = body(UUID.randomUUID(), "retry me");
        assertThat(sendPlain(key, payload).getResponse().getStatus()).isEqualTo(500);
        assertThat(effects()).isZero();
        assertThat(receipts()).isZero();
        assertThat(sendPlain(key, payload).getResponse().getStatus()).isEqualTo(201);
        assertThat(effects()).isEqualTo(1);
        assertThat(receipts()).isEqualTo(1);
    }

    private MvcResult sendPlain(UUID key, String body) throws Exception {
        return mvc.perform(post(PATH + "/plain").with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(body))
                .andReturn();
    }

    @ParameterizedTest
    @ValueSource(strings = {"callable", "deferred", "web-async", "streaming"})
    void rejectsUnsupportedDirectResponsesBeforeInvokingTheController(String responseType) throws Exception {
        mvc.perform(post(PATH + "/unsupported/" + responseType)
                        .with(jwt().jwt(jwt -> jwt.subject(account.toString())))
                        .header("Idempotency-Key", UUID.randomUUID()))
                .andExpect(status().isInternalServerError());
        assertThat(mutations.calls.get()).isZero();
        assertThat(effects()).isZero();
        assertThat(receipts()).isZero();
    }

    private void concurrentRequests(boolean firstFails) throws Exception {
        var key = UUID.randomUUID().toString();
        var body = body(UUID.randomUUID(), "home");
        mutations.entered = new CountDownLatch(1);
        mutations.release = new CountDownLatch(1);
        mutations.failNext.set(firstFails);
        try (var pool = Executors.newFixedThreadPool(2)) {
            var first = pool.submit(() -> send(account, key, body));
            assertThat(mutations.entered.await(10, TimeUnit.SECONDS)).isTrue();
            var second = pool.submit(() -> send(account, key, body));
            try {
                assertThatThrownBy(() -> second.get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
            } finally {
                mutations.release.countDown();
            }
            var firstResponse = first.get(10, TimeUnit.SECONDS);
            var secondResponse = second.get(10, TimeUnit.SECONDS);
            if (firstFails) {
                assertThat(firstResponse.getResponse().getStatus()).isEqualTo(500);
                assertThat(secondResponse.getResponse().getStatus()).isEqualTo(201);
                assertThat(mutations.calls.get()).isEqualTo(2);
            } else {
                assertSameSuccess(firstResponse, secondResponse);
                assertThat(mutations.calls.get()).isEqualTo(1);
            }
        } finally {
            mutations.release.countDown();
        }
        assertThat(effects()).isEqualTo(1);
        assertThat(receipts()).isEqualTo(1);
    }

    private void assertFailureThenRetry() throws Exception {
        var key = UUID.randomUUID().toString();
        var body = body(UUID.randomUUID(), "home");
        var failed = send(account, key, body).getResponse();
        assertThat(failed.getStatus()).isEqualTo(500);
        assertThat(failed.getHeader("Location")).isNull();
        assertThat(effects()).isZero();
        assertThat(receipts()).isZero();
        assertThat(send(account, key, body).getResponse().getStatus()).isEqualTo(201);
        assertThat(effects()).isEqualTo(1);
        assertThat(receipts()).isEqualTo(1);
    }

    private void assertSameSuccess(MvcResult first, MvcResult second) {
        var original = first.getResponse();
        var replay = second.getResponse();
        assertThat(original.getStatus()).isEqualTo(201);
        assertThat(replay.getStatus()).isEqualTo(201);
        assertThat(replay.getContentAsByteArray()).isEqualTo(original.getContentAsByteArray());
        for (String header : new String[]{"Content-Type", "Location", "ETag"}) {
            assertThat(replay.getHeader(header)).isEqualTo(original.getHeader(header));
        }
        assertThat(replay.getHeader("Cache-Control")).isEqualTo("no-store");
    }

    private MvcResult send(UUID user, String key, String body) throws Exception {
        return mvc.perform(post(PATH).with(jwt().jwt(jwt -> jwt.subject(user.toString())))
                        .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(body))
                .andReturn();
    }

    private UUID newAccount() {
        return users.saveAndFlush(new User(UUID.randomUUID() + "@test.invalid", "Test", "User")).getId();
    }

    private String body(UUID id, String name) {
        return "{\"id\":\"" + id + "\",\"name\":\"" + name + "\"}";
    }

    private int effects() {
        return jdbc.queryForObject("SELECT count(*) FROM idempotency_test_effect", Integer.class);
    }

    private int receipts() {
        return jdbc.queryForObject("SELECT count(*) FROM processed_request", Integer.class);
    }

    record Mutation(@NotNull UUID id, @NotBlank String name) {}

    record PlainResponse(UUID id, String name, Instant createdAt, Object value) {}

    @TestComponent
    @RestController
    @RequestMapping(PATH)
    static class Mutations {
        private final JdbcTemplate jdbc;
        final AtomicInteger calls = new AtomicInteger();
        final AtomicBoolean failNext = new AtomicBoolean();
        final AtomicBoolean failSerializationNext = new AtomicBoolean();
        final AtomicBoolean failCommitNext = new AtomicBoolean();
        final AtomicBoolean errorResponseNext = new AtomicBoolean();
        volatile CountDownLatch entered;
        volatile CountDownLatch release;

        Mutations(JdbcTemplate jdbc) { this.jdbc = jdbc; }

        @PostMapping
        @Idempotent("test.create")
        ResponseEntity<Map<String, Object>> create(@Valid @RequestBody Mutation request, Authentication authentication) throws Exception {
            calls.incrementAndGet();
            jdbc.update("INSERT INTO idempotency_test_effect VALUES (?, ?, ?)", request.id(), request.name(),
                    failCommitNext.getAndSet(false) ? UUID.randomUUID() : UUID.fromString(authentication.getName()));
            if (entered != null && entered.getCount() > 0) {
                entered.countDown();
                if (!release.await(10, TimeUnit.SECONDS)) {
                    throw new IllegalStateException("Test did not release the transaction.");
                }
            }
            if (failNext.getAndSet(false)) {
                throw new IllegalStateException("Failure after database write.");
            }
            if (errorResponseNext.getAndSet(false)) {
                return ResponseEntity.unprocessableContent().body(Map.of("error", "rejected"));
            }
            var result = Map.<String, Object>of("id", request.id(), "name", request.name(), "createdAt", Instant.now(),
                    "value", failSerializationNext.getAndSet(false) ? new BrokenResponse() : "ok");
            return ResponseEntity.created(URI.create(PATH + "/" + request.id())).eTag("\"initial\"").body(result);
        }

        @PostMapping("/other")
        @Idempotent("test.other")
        ResponseEntity<Map<String, Object>> other(@Valid @RequestBody Mutation request, Authentication authentication) throws Exception {
            return create(request, authentication);
        }

        @DeleteMapping("/{id}")
        @Idempotent("test.delete")
        ResponseEntity<Void> remove(@PathVariable UUID id) {
            calls.incrementAndGet();
            jdbc.update("DELETE FROM idempotency_test_effect WHERE id = ?", id);
            return ResponseEntity.noContent().build();
        }

        @PostMapping("/plain")
        @ResponseStatus(HttpStatus.CREATED)
        @Idempotent("test.plain.create")
        PlainResponse plain(@Valid @RequestBody Mutation request, @CurrentUserId UUID userId) {
            calls.incrementAndGet();
            jdbc.update("INSERT INTO idempotency_test_effect VALUES (?, ?, ?)", request.id(), request.name(), userId);
            if (failNext.getAndSet(false)) {
                throw new IllegalStateException("Failure after database write.");
            }
            return new PlainResponse(request.id(), request.name(), Instant.now(),
                    failSerializationNext.getAndSet(false) ? new BrokenResponse() : "ok");
        }

        @DeleteMapping("/plain/{id}")
        @ResponseStatus(HttpStatus.NO_CONTENT)
        @Idempotent("test.plain.delete")
        void plainRemove(@PathVariable UUID id) {
            calls.incrementAndGet();
            jdbc.update("DELETE FROM idempotency_test_effect WHERE id = ?", id);
        }

        @PostMapping("/unsupported/callable")
        @Idempotent("test.unsupported.callable")
        java.util.concurrent.Callable<PlainResponse> callable() {
            calls.incrementAndGet();
            return null;
        }

        @PostMapping("/unsupported/deferred")
        @Idempotent("test.unsupported.deferred")
        org.springframework.web.context.request.async.DeferredResult<PlainResponse> deferred() {
            calls.incrementAndGet();
            return null;
        }

        @PostMapping("/unsupported/web-async")
        @Idempotent("test.unsupported.web-async")
        org.springframework.web.context.request.async.WebAsyncTask<PlainResponse> webAsync() {
            calls.incrementAndGet();
            return null;
        }

        @PostMapping("/unsupported/streaming")
        @Idempotent("test.unsupported.streaming")
        org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody streaming() {
            calls.incrementAndGet();
            return null;
        }
    }

    static class BrokenResponse {
        public String getValue() { throw new IllegalStateException("Serialization failed."); }
    }

    @TestComponent
    @RestControllerAdvice(assignableTypes = Mutations.class)
    static class Failures extends ResponseEntityExceptionHandler {
        @ExceptionHandler({IllegalStateException.class, org.springframework.dao.DataAccessException.class,
                org.springframework.transaction.TransactionException.class})
        ProblemDetail failure(RuntimeException exception) {
            return ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "Test failure.");
        }
    }
}
