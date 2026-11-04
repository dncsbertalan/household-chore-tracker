package hu.dncs.tracker;

import hu.dncs.tracker.chore.api.web.request.*;
import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import hu.dncs.tracker.chore.application.command.CreateChoreCommand;
import hu.dncs.tracker.chore.application.usecase.CreateChoreUseCase;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.household.application.command.*;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.*;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.*;
import tools.jackson.databind.ObjectMapper;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicReference;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import({TestcontainersConfiguration.class, ChoreCompletionIntegrationTests.TimeConfig.class})
class ChoreCompletionIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired CreateHouseholdUseCase createHousehold;
    @Autowired CreateChoreUseCase createChore;
    @Autowired HouseholdRepository households;
    @Autowired HouseholdRoleRepository roles;
    @Autowired HouseholdMemberRepository members;
    @Autowired PermissionRepository permissions;
    @Autowired JdbcTemplate jdbc;
    @Autowired TestClock clock;

    @BeforeEach void resetTime() { clock.now.set(Instant.parse("2026-11-04T12:00:00Z")); }

    @ParameterizedTest @EnumSource(ChoreCreationPattern.class)
    void completionWithoutApprovalsWorksForEveryTypeAndLeavesCompletedSnapshotsReadOnly(ChoreCreationPattern pattern) throws Exception {
        var f = fixture(pattern, 0);
        var original = active(f);
        var oldId = original.occurrence().choreOccurrenceId();
        var done = act(f, f.user, "occurrences/" + oldId + "/complete", original);
        var historical = done.occurrences().stream().filter(o -> o.choreOccurrenceId().equals(oldId)).findFirst().orElseThrow();
        assertThat(historical.occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.COMPLETED);
        assertThat(historical.title()).isEqualTo(original.occurrence().title());
        assertThat(done.completions()).hasSize(1);
        assertThat(done.completions().getFirst().status()).isEqualTo(ChoreCompletionStatus.APPROVED);
        boolean recurring = pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION;
        assertThat(done.occurrences()).hasSize(recurring ? 2 : 1);
        if (recurring) {
            assertThat(done.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.PENDING);
            assertThat(done.occurrence().choreOccurrenceId()).isNotEqualTo(oldId);
            assertThat(done.occurrence().scheduledAt()).isAfter(clock.instant());
            assertThat(Duration.between(done.occurrence().scheduledAt(), done.occurrence().dueAt())).isEqualTo(Duration.ofHours(2));
            var edit = new UpdateChoreRequest(done.version(), done.schedule().version(), done.occurrence().choreOccurrenceId(),
                    done.occurrence().version(), "Future title", done.description(), pattern, done.schedule().recurrenceUnit(),
                    done.schedule().recurrenceInterval(), done.schedule().startsAt(), done.occurrence().scheduledAt(), done.occurrence().dueAt(),
                    "Europe/Budapest", done.assignedMemberIds(), 0);
            var changed = decode(mvc.perform(put(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))
                    .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(edit)))
                    .andExpect(status().isOk()).andReturn());
            assertThat(changed.occurrences().stream().filter(o -> o.choreOccurrenceId().equals(oldId)).findFirst().orElseThrow()).isEqualTo(historical);
        } else {
            assertThat(done.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.COMPLETED);
            assertThat(done.actions().canComplete()).isFalse();
        }
        send(f, f.user, "occurrences/" + oldId + "/complete", done, UUID.randomUUID()).andExpect(status().isConflict());
    }

    @ParameterizedTest @EnumSource(ChoreCreationPattern.class)
    void distinctApprovalsAreRequiredAndOnlyFinalApprovalCreatesTheNextOccurrence(ChoreCreationPattern pattern) throws Exception {
        var f = fixture(pattern, 2);
        var pending = complete(f, active(f));
        assertThat(pending.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.AWAITING_APPROVAL);
        assertThat(pending.occurrences()).hasSize(1);
        assertThat(pending.actions().canApprove()).isFalse();
        var submission = pending.completions().getFirst();
        var one = act(f, f.reviewer1, "completions/" + submission.choreCompletionId() + "/approve", detail(f, f.reviewer1));
        assertThat(one.occurrences()).hasSize(1);
        assertThat(one.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.AWAITING_APPROVAL);
        assertThat(one.completions().getFirst().approvals()).hasSize(1);
        send(f, f.reviewer1, "completions/" + submission.choreCompletionId() + "/approve", one, UUID.randomUUID()).andExpect(status().isConflict());
        clock.now.set(Instant.parse("2026-11-06T15:00:00Z"));
        var approved = act(f, f.reviewer2, "completions/" + submission.choreCompletionId() + "/approve", detail(f, f.reviewer2));
        assertThat(approved.completions().getFirst().status()).isEqualTo(ChoreCompletionStatus.APPROVED);
        assertThat(approved.completions().getFirst().approvals()).hasSize(2);
        boolean recurring = pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION;
        assertThat(approved.occurrences()).hasSize(recurring ? 2 : 1);
        if (pattern == ChoreCreationPattern.AFTER_COMPLETION) {
            assertThat(approved.occurrence().scheduledAt()).isEqualTo(Instant.parse("2026-11-07T15:00:00Z"));
        }
        if (pattern == ChoreCreationPattern.FIXED) {
            assertThat(approved.occurrence().scheduledAt()).isEqualTo(Instant.parse("2026-11-07T08:00:00Z"));
        }
    }

    @Test void selfApprovalRequiresBothPermissions() throws Exception {
        var f = fixture(ChoreCreationPattern.ONCE, 1);
        var pending = complete(f, active(f));
        var suffix = "completions/" + pending.completions().getFirst().choreCompletionId() + "/approve";
        send(f, f.user, suffix, pending, UUID.randomUUID()).andExpect(status().isForbidden());
        var role = roles.findAllByHouseholdIdOrderByCreatedAtAscHouseholdRoleIdAsc(f.household).stream()
                .filter(r -> r.getHouseholdRoleId().equals(f.role)).findFirst().orElseThrow();
        role.getPermissions().add(permissions.findByName(CHORE_SELF_APPROVE_COMPLETION).orElseThrow());
        role.getPermissions().removeIf(p -> p.getName().equals(CHORE_APPROVE_COMPLETION.name()));
        role = roles.saveAndFlush(role);
        assertThat(detail(f, f.user).actions().canApprove()).isFalse();
        send(f, f.user, suffix, detail(f, f.user), UUID.randomUUID()).andExpect(status().isForbidden());
        role.getPermissions().add(permissions.findByName(CHORE_APPROVE_COMPLETION).orElseThrow());
        role = roles.saveAndFlush(role);
        var allowed = detail(f, f.user);
        assertThat(allowed.actions().canApprove()).isTrue();
        assertThat(act(f, f.user, suffix, allowed).occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.COMPLETED);
    }

    @Test void rejectionKeepsItsAuditTrailAndResubmissionStartsFreshApprovals() throws Exception {
        var f = fixture(ChoreCreationPattern.FIXED, 2);
        var pending = complete(f, active(f));
        var oldCompletion = pending.completions().getFirst().choreCompletionId();
        var rejected = act(f, f.reviewer1, "completions/" + oldCompletion + "/reject", detail(f, f.reviewer1));
        assertThat(rejected.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.PENDING);
        assertThat(rejected.occurrences()).hasSize(1);
        assertThat(rejected.completions().getFirst().status()).isEqualTo(ChoreCompletionStatus.REJECTED);
        var again = complete(f, detail(f, f.user));
        assertThat(again.completions()).hasSize(2);
        var fresh = again.completions().stream().filter(c -> c.status() == ChoreCompletionStatus.AWAITING_APPROVAL).findFirst().orElseThrow();
        assertThat(fresh.choreCompletionId()).isNotEqualTo(oldCompletion);
        assertThat(fresh.approvals()).isEmpty();
        send(f, f.reviewer2, "completions/" + oldCompletion + "/approve", again, UUID.randomUUID()).andExpect(status().isConflict());
    }

    @Test void onDemandNeedsAnExplicitNewOccurrenceAfterCompletion() throws Exception {
        var f = fixture(ChoreCreationPattern.ON_DEMAND, 0);
        var started = active(f);
        send(f, f.user, "occurrences", started, UUID.randomUUID()).andExpect(status().isConflict());
        var done = complete(f, started);
        assertThat(done.actions().canCreateOccurrence()).isTrue();
        var next = act(f, f.user, "occurrences", done);
        assertThat(next.occurrences()).hasSize(2);
        assertThat(next.occurrence().choreOccurrenceId()).isNotEqualTo(done.occurrence().choreOccurrenceId());
        assertThat(next.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.PENDING);
        assertThat(next.occurrence().scheduledAt()).isNull();
    }

    @Test void completionRequiresTheGrantAndAssignmentAndReviewRequiresItsGrant() throws Exception {
        var f = fixture(ChoreCreationPattern.ONCE, 1);
        var original = active(f);
        var suffix = "occurrences/" + original.occurrence().choreOccurrenceId() + "/complete";
        mvc.perform(post(path(f) + "/" + suffix).with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf()).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(request(original))))
                .andExpect(status().isUnauthorized());
        send(f, f.reviewer1, suffix, original, UUID.randomUUID()).andExpect(status().isForbidden());
        var reviewerMember = members.findByHousehold_HouseholdIdAndUserId(f.household, f.reviewer1).orElseThrow();
        var role = roles.findAllByHouseholdIdOrderByCreatedAtAscHouseholdRoleIdAsc(f.household).stream()
                .filter(r -> r.getHouseholdRoleId().equals(reviewerMember.getHouseholdRole().getHouseholdRoleId())).findFirst().orElseThrow();
        role.getPermissions().add(permissions.findByName(CHORE_COMPLETE).orElseThrow());
        role = roles.saveAndFlush(role);
        send(f, f.reviewer1, suffix, original, UUID.randomUUID()).andExpect(status().isForbidden());
        var pending = complete(f, original);
        var outsider = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Other", "User")).getId();
        send(f, outsider, "completions/" + pending.completions().getFirst().choreCompletionId() + "/approve", pending, UUID.randomUUID())
                .andExpect(status().isForbidden());
    }

    @Test void duplicateAndConcurrentCompletionsGenerateOneSuccessor() throws Exception {
        var f = fixture(ChoreCreationPattern.FIXED, 0);
        var original = active(f);
        var suffix = "occurrences/" + original.occurrence().choreOccurrenceId() + "/complete";
        var key = UUID.randomUUID();
        var first = decode(send(f, f.user, suffix, original, key).andExpect(status().isOk()).andReturn());
        var replay = decode(send(f, f.user, suffix, original, key).andExpect(status().isOk()).andReturn());
        assertThat(replay).isEqualTo(first);
        assertThat(detail(f, f.user).occurrences()).hasSize(2);
        var second = active(f);
        var action = "occurrences/" + second.occurrence().choreOccurrenceId() + "/complete";
        try (var pool = Executors.newFixedThreadPool(2)) {
            var gate = new CountDownLatch(1);
            Callable<Integer> operation = () -> { gate.await(); return send(f, f.user, action, second, UUID.randomUUID()).andReturn().getResponse().getStatus(); };
            var a = pool.submit(operation); var b = pool.submit(operation); gate.countDown();
            assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS))).containsExactlyInAnyOrder(200, 409);
        }
        assertThat(detail(f, f.user).occurrences()).hasSize(3);
    }

    @Test void concurrentFinalApprovalsCannotCreateDuplicateSuccessors() throws Exception {
        var f = fixture(ChoreCreationPattern.AFTER_COMPLETION, 1);
        var pending = complete(f, active(f));
        var suffix = "completions/" + pending.completions().getFirst().choreCompletionId() + "/approve";
        try (var pool = Executors.newFixedThreadPool(2)) {
            var gate = new CountDownLatch(1);
            var a = pool.submit(() -> { gate.await(); return send(f, f.reviewer1, suffix, pending, UUID.randomUUID()).andReturn().getResponse().getStatus(); });
            var b = pool.submit(() -> { gate.await(); return send(f, f.reviewer2, suffix, pending, UUID.randomUUID()).andReturn().getResponse().getStatus(); });
            gate.countDown();
            assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS))).containsExactlyInAnyOrder(200, 409);
        }
        var result = detail(f, f.user);
        assertThat(result.occurrences()).hasSize(2);
        assertThat(result.completions().getFirst().approvals()).hasSize(1);
    }

    private ChoreResponse active(Fixture f) throws Exception {
        var response = detail(f, f.user);
        return response.occurrence() == null ? act(f, f.user, "occurrences", response) : response;
    }
    private ChoreResponse complete(Fixture f, ChoreResponse response) throws Exception {
        return act(f, f.user, "occurrences/" + response.occurrence().choreOccurrenceId() + "/complete", response);
    }
    private ChoreResponse act(Fixture f, UUID user, String action, ChoreResponse response) throws Exception {
        return decode(send(f, user, action, response, UUID.randomUUID()).andExpect(status().isOk()).andReturn());
    }
    private ResultActions send(Fixture f, UUID user, String action, ChoreResponse response, UUID key) throws Exception {
        return mvc.perform(post(path(f) + "/" + action).with(jwt().jwt(j -> j.subject(user.toString())))
                .header("Idempotency-Key", key).contentType(APPLICATION_JSON).content(mapper.writeValueAsString(request(response))));
    }
    private ChoreActionRequest request(ChoreResponse response) {
        var pending = response.completions().stream().filter(c -> c.status() == ChoreCompletionStatus.AWAITING_APPROVAL).findFirst().orElse(null);
        return new ChoreActionRequest(response.version(), response.occurrence() == null ? null : response.occurrence().version(), pending == null ? null : pending.version());
    }
    private ChoreResponse detail(Fixture f, UUID user) throws Exception {
        return decode(mvc.perform(get(path(f)).with(jwt().jwt(j -> j.subject(user.toString())))).andExpect(status().isOk()).andReturn());
    }
    private ChoreResponse decode(MvcResult result) throws Exception { return mapper.readValue(result.getResponse().getContentAsString(), ChoreResponse.class); }
    private String path(Fixture f) { return "/api/v1/chores/"+f.id; }

    private Fixture fixture(ChoreCreationPattern pattern, int required) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Complete", "User")).getId();
        var household = UUID.randomUUID(); var role = UUID.randomUUID(); var member = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(household, "Home", null,
                List.of(new CreateHouseholdRoleCommand(role, "Completer", Set.of(CHORE_CREATE, CHORE_COMPLETE, CHORE_UPDATE, CHORE_APPROVE_COMPLETION))), role, member), user);
        var reviewerRole = new HouseholdRole(UUID.randomUUID(), household, "Reviewer", false);
        reviewerRole.getPermissions().add(permissions.findByName(CHORE_APPROVE_COMPLETION).orElseThrow());
        reviewerRole = roles.saveAndFlush(reviewerRole);
        var reviewer1 = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Reviewer", "One")).getId();
        var reviewer2 = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Reviewer", "Two")).getId();
        for (var id : List.of(reviewer1, reviewer2)) members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), households.findById(household).orElseThrow(), id, reviewerRole));
        var chore = UUID.randomUUID();
        boolean recurring = pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION;
        var scheduled = pattern == ChoreCreationPattern.ON_DEMAND ? null : Instant.parse("2026-11-01T08:00:00Z");
        createChore.execute(new CreateChoreCommand(chore, household, "Chore", "Snapshot", pattern,
                recurring ? ChoreRecurrenceUnit.DAY : null, 1, scheduled, scheduled == null ? null : scheduled.plusSeconds(7200),
                "Europe/Budapest", List.of(member), required, pattern == ChoreCreationPattern.ONCE ? null : UUID.randomUUID(),
                pattern == ChoreCreationPattern.ON_DEMAND ? null : UUID.randomUUID()), user);
        return new Fixture(user, reviewer1, reviewer2, member, household, role, chore);
    }
    private record Fixture(UUID user, UUID reviewer1, UUID reviewer2, UUID member, UUID household, UUID role, UUID id) {}

    @TestConfiguration static class TimeConfig {
        @Bean @Primary TestClock completionTestClock() { return new TestClock(); }
    }
    static class TestClock extends Clock {
        final AtomicReference<Instant> now = new AtomicReference<>(Instant.parse("2026-11-04T12:00:00Z"));
        @Override public ZoneId getZone() { return ZoneOffset.UTC; }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return now.get(); }
    }
}
