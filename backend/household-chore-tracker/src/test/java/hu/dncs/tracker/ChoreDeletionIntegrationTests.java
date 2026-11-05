package hu.dncs.tracker;

import hu.dncs.tracker.chore.application.usecase.DeleteChoreUseCase;
import hu.dncs.tracker.chore.api.web.request.*;
import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.household.application.HouseholdRoleManagementService;
import hu.dncs.tracker.household.application.command.*;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.*;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicReference;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;
import static org.assertj.core.api.Assertions.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class ChoreDeletionIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CreateHouseholdUseCase createHousehold;
    @Autowired UserRepository users;
    @Autowired HouseholdRepository households;
    @Autowired HouseholdMemberRepository members;
    @Autowired HouseholdRoleRepository roles;
    @Autowired PermissionRepository permissions;
    @Autowired HouseholdRoleManagementService management;
    @Autowired DeleteChoreUseCase deletion;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactions;

    @Test void creatorHouseholdDeletionAndEditingGrantsNeverBypassTheChoreDeletionGrant() throws Exception {
        var f = fixture(EnumSet.complementOf(EnumSet.of(CHORE_DELETE)));
        var chore = create(f, ChoreCreationPattern.ONCE, 0);
        remove(chore.response, f.user, true, UUID.randomUUID()).andExpect(status().isForbidden());
        var foreign = fixture(EnumSet.allOf(HouseholdPermission.class));
        remove(chore.response, foreign.user, true, UUID.randomUUID()).andExpect(status().isForbidden());
        mvc.perform(delete(path(chore.response)).with(csrf()).param("version", "0").param("confirmed", "true")
                .header("Idempotency-Key", UUID.randomUUID())).andExpect(status().isUnauthorized());
        assertThat(read(chore.response.choreId(), f.user).title()).isEqualTo(chore.response.title());
    }

    @Test void deletionGrantAloneCanDeleteAndRemovedMembersCannotUseOldGrants() throws Exception {
        var f = admin(); var chore = create(f, ChoreCreationPattern.ONCE, 0);
        var deleter = person(f, Set.of(CHORE_DELETE));
        remove(chore.response, deleter.getUserId(), true, UUID.randomUUID()).andExpect(status().isNoContent());
        var retained = create(f, ChoreCreationPattern.FIXED, 0);
        person(f, Set.of(HOUSEHOLD_ROLE_UPDATE));
        management.removeMember(f.home, f.member, 0L, f.user);
        remove(retained.response, f.user, true, UUID.randomUUID()).andExpect(status().isForbidden());
        assertThat(jdbc.queryForObject("select count(*) from chore where chore_id=?", Long.class, retained.response.choreId())).isEqualTo(1);
    }

    @Test void explicitConfirmationAndFreshVersionAreRequiredBeforeRemovingAnyData() throws Exception {
        var f = admin(); var chore = create(f, ChoreCreationPattern.ONCE, 0);
        remove(chore.response, f.user, false, UUID.randomUUID()).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("chore_delete_confirmation_required"));
        mvc.perform(delete(path(chore.response)).with(jwt().jwt(j -> j.subject(f.user.toString()))).param("version", "0")
                .header("Idempotency-Key", UUID.randomUUID())).andExpect(status().isBadRequest());
        mvc.perform(delete(path(chore.response)).with(jwt().jwt(j -> j.subject(f.user.toString()))).param("confirmed", "true")
                .header("Idempotency-Key", UUID.randomUUID())).andExpect(status().isBadRequest());
        mvc.perform(delete(path(chore.response)).with(jwt().jwt(j -> j.subject(f.user.toString()))).param("confirmed", "true").param("version", "-1")
                .header("Idempotency-Key", UUID.randomUUID())).andExpect(status().isBadRequest());
        action(chore.response, f.user, "occurrences/"+chore.response.occurrence().choreOccurrenceId()+"/complete", null);
        remove(chore.response, f.user, true, UUID.randomUUID()).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("chore_delete_stale"));
        assertThat(read(chore.response.choreId(), f.user).occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.COMPLETED);
    }

    @ParameterizedTest @EnumSource(ChoreCreationPattern.class)
    void everyTypeCanBeDeletedIncludingOnDemandWithoutAnOccurrence(ChoreCreationPattern pattern) throws Exception {
        var f = admin(); var chore = create(f, pattern, 0);
        var unrelated = create(f, ChoreCreationPattern.FIXED, 0);
        assertDeletedGraphOnly(chore.response, unrelated.response, f);
    }

    @ParameterizedTest @EnumSource(ChoreCreationPattern.class)
    void everyTypeDeletesCompletedHistoryApprovalsAndFutureOccurrences(ChoreCreationPattern pattern) throws Exception {
        var f = admin(); var reviewer = person(f, Set.of(CHORE_APPROVE_COMPLETION));
        var created = create(f, pattern, 1); var chore = created.response;
        if (pattern == ChoreCreationPattern.ON_DEMAND) chore = action(chore, f.user, "occurrences", null);
        chore = completeAndApprove(chore, f.user, reviewer.getUserId());
        if (pattern != ChoreCreationPattern.ONCE) {
            if (pattern == ChoreCreationPattern.ON_DEMAND) chore = action(chore, f.user, "occurrences", null);
            chore = completeAndApprove(chore, f.user, reviewer.getUserId());
        }
        assertThat(chore.occurrences()).anyMatch(o -> o.occurrenceStatus() == ChoreOccurrenceStatus.COMPLETED);
        assertThat(chore.completions()).allMatch(c -> !c.approvals().isEmpty());
        var unrelated = create(f, ChoreCreationPattern.FIXED, 0);
        assertDeletedGraphOnly(chore, unrelated.response, f);
        replayCreate(created, f.user).andExpect(status().isGone()).andExpect(jsonPath("$.code").value("chore_deleted"));
    }

    @Test void awaitingApprovalCanBeDeletedWithItsSubmissionAndExistingReviews() throws Exception {
        var f = admin(); var reviewer = person(f, Set.of(CHORE_APPROVE_COMPLETION));
        var chore = create(f, ChoreCreationPattern.AFTER_COMPLETION, 2).response;
        chore = action(chore, f.user, "occurrences/"+chore.occurrence().choreOccurrenceId()+"/complete", null);
        chore = action(chore, reviewer.getUserId(), "completions/"+chore.completions().getFirst().choreCompletionId()+"/approve", chore.completions().getFirst().version());
        assertThat(chore.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.AWAITING_APPROVAL);
        assertDeletedGraphOnly(chore, create(f, ChoreCreationPattern.ONCE, 0).response, f);
    }

    @Test void deletionRedactsOnlyThisChoresSavedResponsesAndRetryKeysRemainReserved() throws Exception {
        var f = admin(); var chore = create(f, ChoreCreationPattern.ONCE, 0);
        var unrelated = create(f, ChoreCreationPattern.ONCE, 0, "Mentions "+chore.response.choreId());
        var editKey = UUID.randomUUID();
        var editBody = mapper.writeValueAsString(new UpdateChoreRequest(chore.response.version(), null,
                chore.response.occurrence().choreOccurrenceId(), chore.response.occurrence().version(), "Private edit", null,
                ChoreCreationPattern.ONCE, null, 1, null, null, null, "Europe/Budapest", List.of(f.member), 0));
        var editRequest = put(path(chore.response)).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", editKey)
                .contentType(APPLICATION_JSON).content(editBody);
        mvc.perform(editRequest).andExpect(status().isOk());
        var current = read(chore.response.choreId(), f.user);
        var key = UUID.randomUUID();
        remove(current, f.user, true, key).andExpect(status().isNoContent());
        remove(current, f.user, true, key).andExpect(status().isNoContent());
        remove(current, f.user, true, UUID.randomUUID()).andExpect(status().isNotFound());
        replayCreate(chore, f.user).andExpect(status().isGone()).andExpect(jsonPath("$.code").value("chore_deleted"));
        mvc.perform(editRequest).andExpect(status().isGone());
        replayCreate(unrelated, f.user).andExpect(status().isCreated());
        assertThat(jdbc.queryForObject("select convert_from(response_body,'UTF8') from processed_request where account_id=? and request_id=?",
                String.class, f.user, editKey)).doesNotContain("Private edit", chore.response.choreId().toString());
        mvc.perform(put(path(chore.response)).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", editKey)
                .contentType(APPLICATION_JSON).content(editBody.replace("Private edit", "Changed"))).andExpect(status().isConflict());
    }

    @Test void storageFailureRollsBackTheChoreGraphAndReceiptRedaction() throws Exception {
        var f = admin(); var created = create(f, ChoreCreationPattern.FIXED, 0);
        var chore = action(created.response, f.user, "occurrences/"+created.response.occurrence().choreOccurrenceId()+"/complete", null);
        var before = totals();
        var suffix = UUID.randomUUID().toString().replace("-", "");
        var trigger = "fail_chore_delete_"+suffix; var function = "reject_chore_delete_"+suffix;
        jdbc.execute("create function "+function+"() returns trigger language plpgsql as $$ begin if old.chore_id = '"+chore.choreId()+"'::uuid then raise exception 'test storage failure'; end if; return old; end $$");
        jdbc.execute("create trigger "+trigger+" before delete on chore for each row execute function "+function+"()");
        try {
            assertThatThrownBy(() -> remove(chore, f.user, true, UUID.randomUUID())).isInstanceOf(Exception.class);
            assertThat(totals()).isEqualTo(before);
            assertThat(read(chore.choreId(), f.user)).isEqualTo(chore);
            replayCreate(created, f.user).andExpect(status().isCreated());
        } finally {
            jdbc.execute("drop trigger "+trigger+" on chore"); jdbc.execute("drop function "+function+"()");
        }
    }

    @Test void deletionWaitingForPermissionRevocationCannotUseTheOldGrant() throws Exception {
        var f = admin(); var chore = create(f, ChoreCreationPattern.ONCE, 0).response;
        var deleter = person(f, Set.of(CHORE_DELETE));
        try (var pool = Executors.newSingleThreadExecutor()) {
            var pending = new AtomicReference<Future<Integer>>();
            new TransactionTemplate(transactions).execute(status -> {
                management.update(f.home, deleter.getHouseholdRole().getHouseholdRoleId(),
                        new SaveHouseholdRoleCommand("Revoked", List.of(HOUSEHOLD_ROLE_VIEW), 0L), f.user);
                pending.set(pool.submit(() -> remove(chore, deleter.getUserId(), true, UUID.randomUUID()).andReturn().getResponse().getStatus()));
                assertThatThrownBy(() -> pending.get().get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                return null;
            });
            assertThat(pending.get().get(15, TimeUnit.SECONDS)).isEqualTo(403);
        }
        assertThat(read(chore.choreId(), f.user)).isEqualTo(chore);
    }

    @Test void completionWaitingForDeletionCannotGenerateAnotherRecurringOccurrence() throws Exception {
        var f = admin(); var chore = create(f, ChoreCreationPattern.FIXED, 0).response;
        var body = mapper.writeValueAsString(new ChoreActionRequest(chore.version(), chore.occurrence().version(), null));
        try (var pool = Executors.newSingleThreadExecutor()) {
            var pending = new AtomicReference<Future<Integer>>();
            new TransactionTemplate(transactions).execute(status -> {
                deletion.execute(chore.choreId(), chore.version(), true, f.user);
                pending.set(pool.submit(() -> mvc.perform(post(path(chore)+"/occurrences/"+chore.occurrence().choreOccurrenceId()+"/complete")
                        .with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                        .contentType(APPLICATION_JSON).content(body)).andReturn().getResponse().getStatus()));
                assertThatThrownBy(() -> pending.get().get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                return null;
            });
            assertThat(pending.get().get(15, TimeUnit.SECONDS)).isEqualTo(404);
        }
        assertThat(jdbc.queryForObject("select count(*) from chore_occurrence where chore_id=?", Long.class, chore.choreId())).isZero();
    }

    @Test void concurrentDeletesCommitOnceAndTheSuccessfulRequestCanBeRetried() throws Exception {
        var f = admin(); var chore = create(f, ChoreCreationPattern.ONCE, 0).response;
        var first = UUID.randomUUID(); var second = UUID.randomUUID();
        try (var pool = Executors.newFixedThreadPool(2)) {
            var gate = new CountDownLatch(1);
            var a = pool.submit(() -> { gate.await(); return remove(chore, f.user, true, first).andReturn().getResponse().getStatus(); });
            var b = pool.submit(() -> { gate.await(); return remove(chore, f.user, true, second).andReturn().getResponse().getStatus(); });
            gate.countDown(); var aStatus = a.get(15, TimeUnit.SECONDS); var bStatus = b.get(15, TimeUnit.SECONDS);
            assertThat(List.of(aStatus, bStatus)).containsExactlyInAnyOrder(204, 404);
            remove(chore, f.user, true, aStatus == 204 ? first : second).andExpect(status().isNoContent());
        }
    }

    private void assertDeletedGraphOnly(ChoreResponse chore, ChoreResponse unrelated, Fixture f) throws Exception {
        var before = totals(); var owned = owned(chore.choreId());
        remove(chore, f.user, true, UUID.randomUUID()).andExpect(status().isNoContent());
        var after = totals();
        before.forEach((table, count) -> assertThat(after.get(table)).as(table).isEqualTo(count-owned.getOrDefault(table, 0L)));
        assertThat(read(unrelated.choreId(), f.user)).isEqualTo(unrelated);
        assertThat(households.existsById(f.home)).isTrue();
        mvc.perform(get(path(chore)).with(jwt().jwt(j -> j.subject(f.user.toString())))).andExpect(status().isNotFound());
    }
    private ResultActions remove(ChoreResponse chore, UUID actor, boolean confirmed, UUID key) throws Exception {
        return mvc.perform(delete(path(chore)).with(jwt().jwt(j -> j.subject(actor.toString()))).header("Idempotency-Key", key)
                .param("version", chore.version().toString()).param("confirmed", String.valueOf(confirmed)));
    }
    private Created create(Fixture f, ChoreCreationPattern pattern, int approvals) throws Exception { return create(f, pattern, approvals, "Private chore"); }
    private Created create(Fixture f, ChoreCreationPattern pattern, int approvals, String title) throws Exception {
        var body = mapper.writeValueAsString(new CreateChoreRequest(UUID.randomUUID(), f.home, title, null, pattern,
                pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION ? ChoreRecurrenceUnit.DAY : null,
                1, pattern == ChoreCreationPattern.FIXED ? Instant.now().plusSeconds(60) : null, null, "Europe/Budapest", List.of(f.member), approvals,
                pattern == ChoreCreationPattern.ONCE ? null : UUID.randomUUID(), pattern == ChoreCreationPattern.ON_DEMAND ? null : UUID.randomUUID()));
        var key = UUID.randomUUID();
        var result = mvc.perform(post("/api/v1/chores").with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", key)
                .contentType(APPLICATION_JSON).content(body)).andExpect(status().isCreated()).andReturn();
        var response = mapper.readValue(result.getResponse().getContentAsString(), ChoreResponse.class);
        return new Created(read(response.choreId(), f.user), body, key);
    }
    private ResultActions replayCreate(Created chore, UUID user) throws Exception {
        return mvc.perform(post("/api/v1/chores").with(jwt().jwt(j -> j.subject(user.toString()))).header("Idempotency-Key", chore.key)
                .contentType(APPLICATION_JSON).content(chore.body));
    }
    private ChoreResponse completeAndApprove(ChoreResponse chore, UUID actor, UUID reviewer) throws Exception {
        var pending = action(chore, actor, "occurrences/"+chore.occurrence().choreOccurrenceId()+"/complete", null);
        return action(pending, reviewer, "completions/"+pending.completions().getFirst().choreCompletionId()+"/approve", pending.completions().getFirst().version());
    }
    private ChoreResponse action(ChoreResponse chore, UUID actor, String action, Long completionVersion) throws Exception {
        var request = post(path(chore)+"/"+action).with(jwt().jwt(j -> j.subject(actor.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .contentType(APPLICATION_JSON).content(mapper.writeValueAsString(new ChoreActionRequest(chore.version(),
                        chore.occurrence() == null ? null : chore.occurrence().version(), completionVersion)));
        return mapper.readValue(mvc.perform(request).andExpect(status().isOk()).andReturn().getResponse().getContentAsString(), ChoreResponse.class);
    }
    private ChoreResponse read(UUID id, UUID user) throws Exception {
        var request = get("/api/v1/chores/"+id).with(jwt().jwt(j -> j.subject(user.toString())));
        return mapper.readValue(mvc.perform(request).andExpect(status().isOk()).andReturn().getResponse().getContentAsString(), ChoreResponse.class);
    }
    private Fixture admin() { return fixture(EnumSet.allOf(HouseholdPermission.class)); }
    private Fixture fixture(Set<HouseholdPermission> grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Chore", "Manager")).getId();
        var home = UUID.randomUUID(); var role = UUID.randomUUID(); var member = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(home, "Home", null, List.of(new CreateHouseholdRoleCommand(role, "Administrator", grants)), role, member), user);
        return new Fixture(user, home, member);
    }
    private HouseholdMember person(Fixture f, Set<HouseholdPermission> grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Other", "Member")).getId();
        var role = new HouseholdRole(UUID.randomUUID(), f.home, "Other role", false);
        grants.forEach(g -> role.getPermissions().add(permissions.findByName(g).orElseThrow())); roles.saveAndFlush(role);
        return members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), households.findById(f.home).orElseThrow(), user, role));
    }
    private static final Map<String, String> SCOPES = Map.of(
        "chore", "chore t where t.chore_id=?",
        "chore_schedule", "chore_schedule t where t.chore_id=?",
        "chore_assigned_member", "chore_assigned_member t where t.chore_id=?",
        "chore_occurrence", "chore_occurrence t where t.chore_id=?",
        "chore_occurrence_assigned_member", "chore_occurrence_assigned_member t join chore_occurrence o on o.chore_occurrence_id=t.chore_occurrence_id where o.chore_id=?",
        "chore_completion", "chore_completion t join chore_occurrence o on o.chore_occurrence_id=t.chore_occurrence_id where o.chore_id=?",
        "chore_approval", "chore_approval t join chore_completion c on c.chore_completion_id=t.chore_completion_id join chore_occurrence o on o.chore_occurrence_id=c.chore_occurrence_id where o.chore_id=?"
    );
    private Map<String, Long> totals() {
        var counts = new HashMap<String, Long>();
        for (var table : SCOPES.keySet()) counts.put(table, jdbc.queryForObject("select count(*) from "+table, Long.class));
        for (var table : List.of("users", "household", "household_member", "household_role", "household_invitation", "household_role_permission")) {
            counts.put(table, jdbc.queryForObject("select count(*) from "+table, Long.class));
        }
        return counts;
    }
    private Map<String, Long> owned(UUID id) {
        var counts = new HashMap<String, Long>();
        SCOPES.forEach((table, scope) -> counts.put(table, jdbc.queryForObject("select count(*) from "+scope, Long.class, id)));
        return counts;
    }
    private String path(ChoreResponse chore) { return "/api/v1/chores/"+chore.choreId(); }
    private record Fixture(UUID user, UUID home, UUID member) {}
    private record Created(ChoreResponse response, String body, UUID key) {}
}
