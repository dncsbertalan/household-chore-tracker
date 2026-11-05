package hu.dncs.tracker;

import hu.dncs.tracker.household.application.HouseholdInvitationService;
import hu.dncs.tracker.household.application.HouseholdRoleManagementService;
import hu.dncs.tracker.household.application.command.*;
import hu.dncs.tracker.household.application.usecase.DeleteHouseholdUseCase;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import hu.dncs.tracker.household.api.web.request.*;
import hu.dncs.tracker.chore.application.usecase.CreateChoreUseCase;
import hu.dncs.tracker.chore.application.command.CreateChoreCommand;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.chore.api.web.request.ChoreActionRequest;
import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.*;
import org.springframework.jdbc.core.JdbcTemplate;
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
class HouseholdDeletionIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired HouseholdRepository households;
    @Autowired HouseholdMemberRepository members;
    @Autowired HouseholdRoleRepository roles;
    @Autowired PermissionRepository permissions;
    @Autowired HouseholdInvitationService invitations;
    @Autowired HouseholdRoleManagementService management;
    @Autowired CreateChoreUseCase createChore;
    @Autowired DeleteHouseholdUseCase deleteHousehold;
    @Autowired PlatformTransactionManager transactions;
    @Autowired JdbcTemplate jdbc;

    @Test void creatorRoleAdministratorAndMemberRemoverStillNeedTheDeletionPermission() throws Exception {
        var f = fixture(EnumSet.complementOf(EnumSet.of(HOUSEHOLD_DELETE)));
        var outsider = fixture(EnumSet.allOf(HouseholdPermission.class));
        remove(f, f.user, 0, true, UUID.randomUUID()).andExpect(status().isForbidden());
        remove(f, outsider.user, 0, true, UUID.randomUUID()).andExpect(status().isForbidden());
        mvc.perform(delete(path(f)).with(csrf()).param("version", "0").param("confirmed", "true")
                .header("Idempotency-Key", UUID.randomUUID())).andExpect(status().isUnauthorized());
        assertThat(households.existsById(f.home)).isTrue();
        assertThat(households.existsById(outsider.home)).isTrue();
    }

    @Test void removedMembershipCannotDeleteEvenWhenItsRoleStillHasTheGrant() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class));
        var removed = person(f, Set.of(HOUSEHOLD_DELETE));
        management.removeMember(f.home, removed.getHouseholdMemberId(), removed.getVersion(), f.user);
        remove(f, removed.getUserId(), 0, true, UUID.randomUUID()).andExpect(status().isForbidden());
        assertThat(households.existsById(f.home)).isTrue();
    }

    @Test void explicitConfirmationAndCurrentVersionAreRequiredBeforeAnyDeletion() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_DELETE));
        remove(f, f.user, 0, false, UUID.randomUUID()).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("household_delete_confirmation_required"));
        mvc.perform(delete(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString()))).param("version", "0")
                .header("Idempotency-Key", UUID.randomUUID())).andExpect(status().isBadRequest());
        remove(f, f.user, 1, true, UUID.randomUUID()).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_delete_stale"));
        remove(f, f.user, -1, true, UUID.randomUUID()).andExpect(status().isBadRequest());
        mvc.perform(delete(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString()))).param("confirmed", "true")
                .header("Idempotency-Key", UUID.randomUUID())).andExpect(status().isBadRequest());
        assertThat(households.existsById(f.home)).isTrue();
        // Deleting the entire household needs no additional role/member grants or remaining administrator.
        remove(f, f.user, 0, true, UUID.randomUUID()).andExpect(status().isNoContent());
        assertThat(households.existsById(f.home)).isFalse();
    }

    @Test void deletingOneHouseholdRemovesItsEntireGraphAndPreservesOtherHouseholdsAndAccounts() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class));
        var other = fixture(f.user, EnumSet.allOf(HouseholdPermission.class), "Unrelated "+f.home);
        var worker = person(f, Set.of(CHORE_COMPLETE, CHORE_APPROVE_COMPLETION));
        for (var pattern : ChoreCreationPattern.values()) {
            var chore = chore(f, worker, pattern, pattern == ChoreCreationPattern.ONCE ? 1 : 0);
            if (pattern == ChoreCreationPattern.ON_DEMAND) chore = action(chore, worker.getUserId(), "occurrences", null);
            chore = action(chore, worker.getUserId(), "occurrences/"+chore.occurrence().choreOccurrenceId()+"/complete", null);
            if (pattern == ChoreCreationPattern.ONCE) action(chore, f.user,
                    "completions/"+chore.completions().getFirst().choreCompletionId()+"/approve", chore.completions().getFirst().version());
        }
        chore(f, worker, ChoreCreationPattern.ONCE, 0);
        var pending = chore(f, worker, ChoreCreationPattern.AFTER_COMPLETION, 1);
        action(pending, worker.getUserId(), "occurrences/"+pending.occurrence().choreOccurrenceId()+"/complete", null);
        var pendingInvite = invitations.invite(f.home, new InviteHouseholdMemberCommand(UUID.randomUUID()+"@test.invalid", f.role), f.user);
        var revoked = invitations.invite(f.home, new InviteHouseholdMemberCommand(UUID.randomUUID()+"@test.invalid", f.role), f.user);
        invitations.revoke(f.home, revoked.householdInvitationId(), f.user);
        var invitee = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "New", "Member"));
        var accepted = invitations.invite(f.home, new InviteHouseholdMemberCommand(invitee.getEmail(), f.role), f.user);
        invitations.accept(accepted.householdInvitationId(), invitee.getId());
        management.removeMember(f.home, worker.getHouseholdMemberId(), worker.getVersion(), f.user);
        var system = new HouseholdRole(UUID.randomUUID(), f.home, "System", true); roles.saveAndFlush(system);
        var before = totals(); var owned = owned(f.home);
        assertThat(owned.get("chore_completion")).isPositive();
        assertThat(owned.get("chore_approval")).isPositive();
        assertThat(owned.get("household_invitation")).isEqualTo(3);
        var key = UUID.randomUUID();
        remove(f, f.user, 0, true, key).andExpect(status().isNoContent());
        var after = totals();
        before.forEach((table, count) -> assertThat(after.get(table)).as(table).isEqualTo(count - owned.getOrDefault(table, 0L)));
        assertThat(members.findById(worker.getHouseholdMemberId())).isEmpty();
        assertThat(users.existsById(f.user)).isTrue();
        assertThat(users.existsById(worker.getUserId())).isTrue();
        assertThat(households.existsById(other.home)).isTrue();
        mvc.perform(get("/api/v1/household-invitations/"+pendingInvite.householdInvitationId())
                .with(jwt().jwt(j -> j.subject(invitee.getId().toString())))).andExpect(status().isNotFound());
        remove(f, f.user, 0, true, key).andExpect(status().isNoContent());
        remove(f, f.user, 0, true, UUID.randomUUID()).andExpect(status().isNotFound());
        replayCreate(f).andExpect(status().isGone()).andExpect(jsonPath("$.code").value("household_deleted"));
        // The unrelated name contains the deleted UUID; scope matching must not redact incidental text.
        replayCreate(other).andExpect(status().isCreated()).andExpect(jsonPath("$.householdId").value(other.home.toString()));
    }

    @Test void roleAndInvitationReceiptsLoseTheirDeletedRepresentationsButRetainReservedKeys() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class));
        var roleKey = UUID.randomUUID();
        var roleBody = mapper.writeValueAsString(new UpdateHouseholdRoleRequest("Private role", List.of(HOUSEHOLD_DELETE, HOUSEHOLD_ROLE_UPDATE, HOUSEHOLD_MEMBER_INVITE), 0L));
        mvc.perform(put(path(f)+"/roles/"+f.role).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", roleKey)
                .contentType(APPLICATION_JSON).content(roleBody)).andExpect(status().isOk());
        var invitationKey = UUID.randomUUID();
        var invitationBody = "{\"email\":\"private@test.invalid\",\"householdRoleId\":\""+f.role+"\"}";
        mvc.perform(post(path(f)+"/invitations").with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", invitationKey)
                .contentType(APPLICATION_JSON).content(invitationBody)).andExpect(status().isCreated());
        remove(f, f.user, 0, true, UUID.randomUUID()).andExpect(status().isNoContent());
        mvc.perform(put(path(f)+"/roles/"+f.role).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", roleKey)
                .contentType(APPLICATION_JSON).content(roleBody)).andExpect(status().isGone())
                .andExpect(jsonPath("$.code").value("household_deleted"));
        mvc.perform(post(path(f)+"/invitations").with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", invitationKey)
                .contentType(APPLICATION_JSON).content(invitationBody)).andExpect(status().isGone());
        assertThat(jdbc.queryForObject("select convert_from(response_body, 'UTF8') from processed_request where account_id=? and request_id=?",
                String.class, f.user, roleKey)).doesNotContain("Private role", f.home.toString());
        mvc.perform(put(path(f)+"/roles/"+f.role).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", roleKey)
                .contentType(APPLICATION_JSON).content(roleBody.replace("Private role", "Changed"))).andExpect(status().isConflict());
    }

    @Test void storageFailureRollsBackAllDataDeletionAndReceiptRedaction() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class));
        var worker = person(f, Set.of(CHORE_COMPLETE));
        chore(f, worker, ChoreCreationPattern.FIXED, 0);
        invitations.invite(f.home, new InviteHouseholdMemberCommand(UUID.randomUUID()+"@test.invalid", f.role), f.user);
        var before = totals();
        var suffix = UUID.randomUUID().toString().replace("-", "");
        var trigger = "fail_delete_"+suffix; var function = "reject_delete_"+suffix;
        jdbc.execute("create function "+function+"() returns trigger language plpgsql as $$ begin if old.household_id = '"+f.home+"'::uuid then raise exception 'test storage failure'; end if; return old; end $$");
        jdbc.execute("create trigger "+trigger+" before delete on household for each row execute function "+function+"()");
        try {
            assertThatThrownBy(() -> remove(f, f.user, 0, true, UUID.randomUUID())).isInstanceOf(Exception.class);
            assertThat(totals()).isEqualTo(before);
            replayCreate(f).andExpect(status().isCreated());
        } finally {
            jdbc.execute("drop trigger "+trigger+" on household");
            jdbc.execute("drop function "+function+"()");
        }
    }

    @Test void deleteWaitingBehindPermissionRevocationChecksTheNewGrants() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class));
        var deleter = person(f, Set.of(HOUSEHOLD_DELETE));
        try (var pool = Executors.newSingleThreadExecutor()) {
            var pending = new AtomicReference<Future<Integer>>();
            new TransactionTemplate(transactions).execute(status -> {
                management.update(f.home, deleter.getHouseholdRole().getHouseholdRoleId(),
                        new SaveHouseholdRoleCommand("Revoked", List.of(HOUSEHOLD_ROLE_VIEW), 0L), f.user);
                pending.set(pool.submit(() -> remove(f, deleter.getUserId(), 0, true, UUID.randomUUID()).andReturn().getResponse().getStatus()));
                assertThatThrownBy(() -> pending.get().get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                return null;
            });
            assertThat(pending.get().get(15, TimeUnit.SECONDS)).isEqualTo(403);
        }
        assertThat(households.existsById(f.home)).isTrue();
    }

    @Test void concurrentDeletesCommitOnceAndRepeatOfSuccessfulRequestIsSafe() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_DELETE)); var first = UUID.randomUUID(); var second = UUID.randomUUID();
        try (var pool = Executors.newFixedThreadPool(2)) {
            var gate = new CountDownLatch(1);
            var a = pool.submit(() -> { gate.await(); return remove(f, f.user, 0, true, first).andReturn().getResponse().getStatus(); });
            var b = pool.submit(() -> { gate.await(); return remove(f, f.user, 0, true, second).andReturn().getResponse().getStatus(); });
            gate.countDown();
            var aStatus = a.get(15, TimeUnit.SECONDS); var bStatus = b.get(15, TimeUnit.SECONDS);
            assertThat(List.of(aStatus, bStatus)).containsExactlyInAnyOrder(204, 404);
            remove(f, f.user, 0, true, aStatus == 204 ? first : second).andExpect(status().isNoContent());
        }
    }

    @Test void choreCreationWaitingForDeletionCannotRepopulateTheHousehold() throws Exception {
        var f = fixture(EnumSet.allOf(HouseholdPermission.class)); var choreId = UUID.randomUUID();
        try (var pool = Executors.newSingleThreadExecutor()) {
            var pending = new AtomicReference<Future<?>>();
            new TransactionTemplate(transactions).execute(status -> {
                deleteHousehold.execute(f.home, 0L, true, f.user);
                pending.set(pool.submit(() -> createChore.execute(new CreateChoreCommand(choreId, f.home, "Late", null,
                        ChoreCreationPattern.ONCE, null, 1, null, null, "Europe/Budapest", List.of(), 0, null, UUID.randomUUID()), f.user)));
                assertThatThrownBy(() -> pending.get().get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                return null;
            });
            assertThatThrownBy(() -> pending.get().get(15, TimeUnit.SECONDS)).isInstanceOf(ExecutionException.class)
                    .hasCauseInstanceOf(hu.dncs.tracker.chore.application.exception.ChoreNotFoundException.class);
        }
        assertThat(jdbc.queryForObject("select count(*) from chore where chore_id=?", Long.class, choreId)).isZero();
    }

    private ResultActions remove(Fixture f, UUID actor, long version, boolean confirmed, UUID key) throws Exception {
        return mvc.perform(delete(path(f)).with(jwt().jwt(j -> j.subject(actor.toString()))).param("version", String.valueOf(version))
                .param("confirmed", String.valueOf(confirmed)).header("Idempotency-Key", key));
    }
    private ResultActions replayCreate(Fixture f) throws Exception {
        return mvc.perform(post("/api/v1/households").with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", f.createKey)
                .contentType(APPLICATION_JSON).content(f.createBody));
    }
    private Fixture fixture(Set<HouseholdPermission> grants) throws Exception {
        return fixture(users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Delete", "Manager")).getId(), grants, "Private home");
    }
    private Fixture fixture(UUID user, Set<HouseholdPermission> grants, String name) throws Exception {
        var home = UUID.randomUUID(); var role = UUID.randomUUID(); var member = UUID.randomUUID(); var key = UUID.randomUUID();
        var body = mapper.writeValueAsString(new CreateHouseholdRequest(home, name, "Private description",
                List.of(new CreateHouseholdRoleRequest(role, "Administrator", grants)), role, member));
        var f = new Fixture(user, home, role, member, key, body);
        replayCreate(f).andExpect(status().isCreated());
        return f;
    }
    private HouseholdMember person(Fixture f, Set<HouseholdPermission> grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Other", "Member")).getId();
        var role = new HouseholdRole(UUID.randomUUID(), f.home, "Worker", false);
        grants.forEach(g -> role.getPermissions().add(permissions.findByName(g).orElseThrow())); roles.saveAndFlush(role);
        return members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), households.findById(f.home).orElseThrow(), user, role));
    }
    private ChoreResponse chore(Fixture f, HouseholdMember worker, ChoreCreationPattern pattern, int approvals) throws Exception {
        var id = UUID.randomUUID();
        createChore.execute(new CreateChoreCommand(id, f.home, "Private chore", null, pattern,
                pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION ? ChoreRecurrenceUnit.DAY : null,
                1, pattern == ChoreCreationPattern.FIXED ? Instant.now().plusSeconds(60) : null, null, "Europe/Budapest",
                List.of(worker.getHouseholdMemberId()), approvals, pattern == ChoreCreationPattern.ONCE ? null : UUID.randomUUID(),
                pattern == ChoreCreationPattern.ON_DEMAND ? null : UUID.randomUUID()), f.user);
        return mapper.readValue(mvc.perform(get("/api/v1/chores/"+id).with(jwt().jwt(j -> j.subject(worker.getUserId().toString()))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(), ChoreResponse.class);
    }
    private ChoreResponse action(ChoreResponse chore, UUID actor, String action, Long completionVersion) throws Exception {
        return mapper.readValue(mvc.perform(post("/api/v1/chores/"+chore.choreId()+"/"+action).with(jwt().jwt(j -> j.subject(actor.toString())))
                .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(new ChoreActionRequest(chore.version(), chore.occurrence() == null ? null : chore.occurrence().version(), completionVersion))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(), ChoreResponse.class);
    }
    private String path(Fixture f) { return "/api/v1/households/"+f.home; }
    private static final Map<String, String> SCOPES = Map.ofEntries(
        Map.entry("household", "household t where t.household_id=?"),
        Map.entry("household_member", "household_member t where t.household_id=?"),
        Map.entry("household_role", "household_role t where t.household_id=?"),
        Map.entry("household_role_permission", "household_role_permission t join household_role r on r.household_role_id=t.household_role_id where r.household_id=?"),
        Map.entry("household_invitation", "household_invitation t where t.household_id=?"),
        Map.entry("chore", "chore t where t.household_id=?"),
        Map.entry("chore_schedule", "chore_schedule t join chore c on c.chore_id=t.chore_id where c.household_id=?"),
        Map.entry("chore_assigned_member", "chore_assigned_member t join chore c on c.chore_id=t.chore_id where c.household_id=?"),
        Map.entry("chore_occurrence", "chore_occurrence t join chore c on c.chore_id=t.chore_id where c.household_id=?"),
        Map.entry("chore_occurrence_assigned_member", "chore_occurrence_assigned_member t join chore_occurrence o on o.chore_occurrence_id=t.chore_occurrence_id join chore c on c.chore_id=o.chore_id where c.household_id=?"),
        Map.entry("chore_completion", "chore_completion t join chore_occurrence o on o.chore_occurrence_id=t.chore_occurrence_id join chore c on c.chore_id=o.chore_id where c.household_id=?"),
        Map.entry("chore_approval", "chore_approval t join chore_completion s on s.chore_completion_id=t.chore_completion_id join chore_occurrence o on o.chore_occurrence_id=s.chore_occurrence_id join chore c on c.chore_id=o.chore_id where c.household_id=?")
    );
    private Map<String, Long> totals() {
        var counts = new HashMap<String, Long>();
        for (var table : SCOPES.keySet()) counts.put(table, jdbc.queryForObject("select count(*) from "+table, Long.class));
        for (var table : List.of("users", "permission")) counts.put(table, jdbc.queryForObject("select count(*) from "+table, Long.class));
        return counts;
    }
    private Map<String, Long> owned(UUID home) {
        var counts = new HashMap<String, Long>();
        SCOPES.forEach((table, scope) -> counts.put(table, jdbc.queryForObject("select count(*) from "+scope, Long.class, home)));
        return counts;
    }
    private record Fixture(UUID user, UUID home, UUID role, UUID member, UUID createKey, String createBody) {}
}
