package hu.dncs.tracker;

import hu.dncs.tracker.household.application.command.*;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
import hu.dncs.tracker.household.application.HouseholdInvitationService;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import hu.dncs.tracker.household.api.web.request.AssignHouseholdRoleRequest;
import hu.dncs.tracker.household.api.web.request.UpdateHouseholdRoleRequest;
import hu.dncs.tracker.household.api.web.response.HouseholdMemberRemovalResponse;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import hu.dncs.tracker.chore.application.usecase.CreateChoreUseCase;
import hu.dncs.tracker.chore.application.command.CreateChoreCommand;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.chore.api.web.request.ChoreActionRequest;
import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.*;
import tools.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class HouseholdMemberRemovalIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired CreateHouseholdUseCase createHousehold;
    @Autowired CreateChoreUseCase createChore;
    @Autowired HouseholdRepository households;
    @Autowired HouseholdRoleRepository roles;
    @Autowired HouseholdMemberRepository members;
    @Autowired PermissionRepository permissions;
    @Autowired HouseholdInvitationService invitations;
    @Autowired hu.dncs.tracker.household.application.HouseholdRoleManagementService management;
    @Autowired org.springframework.transaction.PlatformTransactionManager transactions;

    @Test void onlyExplicitRemovalPermissionAuthorizesRemovalEvenForTheCreator() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_ROLE_UPDATE, HOUSEHOLD_ROLE_VIEW, HOUSEHOLD_MEMBER_ASSIGN_ROLE));
        var target = person(f, Set.of(CHORE_COMPLETE));
        remove(f, f.user, target, UUID.randomUUID()).andExpect(status().isForbidden());
        var remover = person(f, Set.of(HOUSEHOLD_MEMBER_REMOVE));
        mvc.perform(get(path(f)+"/roles").with(jwt().jwt(j -> j.subject(remover.getUserId().toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$.actions.canRemoveMembers").value(true))
                .andExpect(jsonPath("$.actions.canAssignRoles").value(false))
                .andExpect(jsonPath("$.household.members.length()").value(3));
        remove(f, remover.getUserId(), target, UUID.randomUUID()).andExpect(status().isOk())
                .andExpect(jsonPath("$.management.household.members.length()").value(2));
        var outsider = fixture(EnumSet.allOf(HouseholdPermission.class));
        remove(f, outsider.user, remover, UUID.randomUUID()).andExpect(status().isForbidden());
        mvc.perform(delete(path(f)+"/members/"+remover.getHouseholdMemberId()).param("version", "0").with(csrf()).header("Idempotency-Key", UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }

    @Test void removalRevokesAllMembershipAccessAndExplicitRetriesAreIdempotent() throws Exception {
        var f = admin(); var target = person(f, EnumSet.allOf(HouseholdPermission.class));
        var chore = chore(f, target, ChoreCreationPattern.ONCE, 0);
        var key = UUID.randomUUID();
        var first = remove(f, f.user, target, key).andExpect(status().isOk()).andReturn();
        var replay = remove(f, f.user, target, key).andExpect(status().isOk()).andReturn();
        assertThat(replay.getResponse().getContentAsString()).isEqualTo(first.getResponse().getContentAsString());
        assertThat(members.findById(target.getHouseholdMemberId()).orElseThrow().getRemovedAt()).isNotNull();
        assertThat(members.findByHousehold_HouseholdIdAndUserId(f.household, target.getUserId())).isEmpty();
        assertThat(members.hasPermission(f.household, target.getUserId(), HOUSEHOLD_MEMBER_REMOVE.name())).isFalse();
        for (var url : List.of(path(f), path(f)+"/roles", "/api/v1/chores/"+chore.choreId(), path(f)+"/chores")) {
            mvc.perform(get(url).with(jwt().jwt(j -> j.subject(target.getUserId().toString())))).andExpect(status().isForbidden());
        }
        mvc.perform(get("/api/v1/households").with(jwt().jwt(j -> j.subject(target.getUserId().toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
        mvc.perform(get("/api/v1/chores").with(jwt().jwt(j -> j.subject(target.getUserId().toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
        remove(f, target.getUserId(), members.findById(f.member).orElseThrow(), UUID.randomUUID()).andExpect(status().isForbidden());
        mvc.perform(post(path(f)+"/invitations").with(jwt().jwt(j -> j.subject(target.getUserId().toString()))).header("Idempotency-Key", UUID.randomUUID())
                .contentType(APPLICATION_JSON).content("{\"email\":\"new@test.invalid\",\"householdRoleId\":\""+f.role+"\"}"))
                .andExpect(status().isForbidden());
    }

    @Test void lastAdministratorCannotBeRemovedIncludingByThemselves() throws Exception {
        var f = admin(); var remover = person(f, Set.of(HOUSEHOLD_MEMBER_REMOVE));
        var manager = members.findById(f.member).orElseThrow();
        for (var actor : List.of(f.user, remover.getUserId())) {
            remove(f, actor, manager, UUID.randomUUID()).andExpect(status().isConflict())
                    .andExpect(jsonPath("$.code").value("household_role_last_manager"));
        }
        assertThat(members.findByHousehold_HouseholdIdAndUserId(f.household, f.user)).isPresent();
        assertThat(members.findById(f.member).orElseThrow().getRemovedAt()).isNull();
    }

    @Test void selfRemovalSucceedsWithAnotherAdministratorAndReturnsNoHouseholdData() throws Exception {
        var f = admin(); person(f, Set.of(HOUSEHOLD_ROLE_UPDATE));
        var own = members.findById(f.member).orElseThrow();
        var response = mapper.readValue(remove(f, f.user, own, UUID.randomUUID()).andExpect(status().isOk()).andReturn()
                .getResponse().getContentAsString(), HouseholdMemberRemovalResponse.class);
        assertThat(response.management()).isNull();
        assertThat(response.removedMemberId()).isEqualTo(f.member);
        mvc.perform(get(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))).andExpect(status().isForbidden());
    }

    @Test void householdScopeAndMembershipVersionsPreventWrongOrStaleRemovals() throws Exception {
        var f = admin(); var other = admin();
        remove(f, f.user, members.findById(other.member).orElseThrow(), UUID.randomUUID()).andExpect(status().isNotFound());
        var target = person(f, Set.of(CHORE_COMPLETE));
        mvc.perform(put(path(f)+"/members/"+target.getHouseholdMemberId()+"/role").with(jwt().jwt(j -> j.subject(f.user.toString())))
                .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(new AssignHouseholdRoleRequest(f.role, target.getVersion(), 0L))))
                .andExpect(status().isOk());
        remove(f, f.user, target, UUID.randomUUID()).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_role_stale"));
        mvc.perform(delete(path(f)+"/members/"+target.getHouseholdMemberId()).param("version", "-1")
                .with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID()))
                .andExpect(status().isBadRequest());
        mvc.perform(delete(path(f)+"/members/"+target.getHouseholdMemberId())
                .with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID()))
                .andExpect(status().isBadRequest());
        assertThat(members.findById(target.getHouseholdMemberId()).orElseThrow().getRemovedAt()).isNull();
    }

    @Test void pendingAssignmentsAreRemovedAndRemainingMembersCanCompleteTheChore() throws Exception {
        var f = admin(); var target = person(f, Set.of(CHORE_COMPLETE));
        var chore = chore(f, target, ChoreCreationPattern.ONCE, 0);
        remove(f, f.user, target, UUID.randomUUID()).andExpect(status().isOk());
        var after = readChore(chore.choreId(), f.user);
        assertThat(after.assignedMemberIds()).isEmpty();
        assertThat(after.occurrence().assignedMemberIds()).isEmpty();
        assertThat(after.version()).isGreaterThan(chore.version());
        var completed = complete(after, f.user);
        assertThat(completed.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.COMPLETED);
    }

    @ParameterizedTest @EnumSource(ChoreCreationPattern.class)
    void completedHistoryIsUnchangedForEveryChoreTypeAndFutureAssignmentsAreCleaned(ChoreCreationPattern pattern) throws Exception {
        var f = admin(); var target = person(f, Set.of(CHORE_COMPLETE));
        var chore = chore(f, target, pattern, 0);
        if (pattern == ChoreCreationPattern.ON_DEMAND) {
            chore = decodeChore(mvc.perform(post("/api/v1/chores/"+chore.choreId()+"/occurrences").with(jwt().jwt(j -> j.subject(target.getUserId().toString())))
                    .header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON)
                    .content(mapper.writeValueAsString(new ChoreActionRequest(chore.version(), null, null))))
                    .andExpect(status().isOk()).andReturn());
        }
        var completed = complete(chore, target.getUserId());
        var snapshot = completed.occurrences().stream().filter(o -> o.occurrenceStatus() == ChoreOccurrenceStatus.COMPLETED).findFirst().orElseThrow();
        remove(f, f.user, target, UUID.randomUUID()).andExpect(status().isOk());
        var after = readChore(chore.choreId(), f.user);
        assertThat(after.occurrences().stream().filter(o -> o.choreOccurrenceId().equals(snapshot.choreOccurrenceId())).findFirst().orElseThrow()).isEqualTo(snapshot);
        assertThat(after.completions()).isEqualTo(completed.completions());
        if (pattern != ChoreCreationPattern.ONCE) assertThat(after.assignedMemberIds()).isEmpty();
        if (pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION) {
            assertThat(after.occurrence().assignedMemberIds()).isEmpty();
            assertThat(after.actions().canComplete()).isTrue();
        }
    }

    @Test void pendingCompletionSurvivesRemovalAndReinvitationDoesNotBypassSelfApproval() throws Exception {
        var f = admin(); var target = person(f, Set.of(CHORE_COMPLETE, CHORE_APPROVE_COMPLETION));
        var pending = complete(chore(f, target, ChoreCreationPattern.AFTER_COMPLETION, 1), target.getUserId());
        remove(f, f.user, target, UUID.randomUUID()).andExpect(status().isOk());
        var after = readChore(pending.choreId(), f.user);
        assertThat(after.completions()).isEqualTo(pending.completions());
        assertThat(after.occurrence().assignedMemberIds()).isEmpty();
        var email = users.findById(target.getUserId()).orElseThrow().getEmail();
        var invitation = invitations.invite(f.household, new InviteHouseholdMemberCommand(email, target.getHouseholdRole().getHouseholdRoleId()), f.user);
        var joined = invitations.accept(invitation.householdInvitationId(), target.getUserId());
        assertThat(joined.membership().getHouseholdMemberId()).isEqualTo(target.getHouseholdMemberId());
        var restored = readChore(pending.choreId(), target.getUserId());
        assertThat(restored.actions().canApprove()).isFalse();
        review(restored, target.getUserId()).andExpect(status().isForbidden());
        var approved = decodeChore(review(readChore(pending.choreId(), f.user), f.user).andExpect(status().isOk()).andReturn());
        assertThat(approved.occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.PENDING);
        assertThat(approved.occurrence().assignedMemberIds()).isEmpty();
        assertThat(approved.completions().getFirst().status()).isEqualTo(ChoreCompletionStatus.APPROVED);
    }

    @Test void removingAReviewerAndCreatorPreservesCompletedOccurrencesAndApprovalAttribution() throws Exception {
        var f = admin();
        var remaining = person(f, Set.of(HOUSEHOLD_ROLE_UPDATE, CHORE_COMPLETE, CHORE_APPROVE_COMPLETION));
        var submitted = complete(chore(f, remaining, ChoreCreationPattern.AFTER_COMPLETION, 1), remaining.getUserId());
        var approved = decodeChore(review(readChore(submitted.choreId(), f.user), f.user).andExpect(status().isOk()).andReturn());
        var completed = approved.occurrences().stream().filter(o -> o.occurrenceStatus() == ChoreOccurrenceStatus.COMPLETED).findFirst().orElseThrow();
        remove(f, f.user, members.findById(f.member).orElseThrow(), UUID.randomUUID()).andExpect(status().isOk());
        var after = readChore(submitted.choreId(), remaining.getUserId());
        assertThat(after.occurrences().stream().filter(o -> o.choreOccurrenceId().equals(completed.choreOccurrenceId())).findFirst().orElseThrow()).isEqualTo(completed);
        assertThat(after.completions()).isEqualTo(approved.completions());
        assertThat(after.completions().getFirst().approvals().getFirst().reviewedByHouseholdMemberId()).isEqualTo(f.member);
        assertThat(after.createdByHouseholdMemberId()).isEqualTo(f.member);
    }

    @Test void choreWriteWaitingForRemovalCannotUseTheRemovedMembersOldPermissions() throws Exception {
        var f = admin(); var target = person(f, Set.of(CHORE_COMPLETE));
        var id = UUID.randomUUID();
        createChore.execute(new CreateChoreCommand(id, f.household, "Unassigned", null, ChoreCreationPattern.ONCE,
                null, 1, null, null, "Europe/Budapest", List.of(), 0, null, UUID.randomUUID()), f.user);
        var chore = readChore(id, target.getUserId());
        var body = mapper.writeValueAsString(new ChoreActionRequest(chore.version(), chore.occurrence().version(), null));
        try (var pool = Executors.newSingleThreadExecutor()) {
            var pending = new java.util.concurrent.atomic.AtomicReference<Future<Integer>>();
            new org.springframework.transaction.support.TransactionTemplate(transactions).execute(status -> {
                management.removeMember(f.household, target.getHouseholdMemberId(), target.getVersion(), f.user);
                pending.set(pool.submit(() -> mvc.perform(post("/api/v1/chores/"+id+"/occurrences/"+chore.occurrence().choreOccurrenceId()+"/complete")
                        .with(jwt().jwt(j -> j.subject(target.getUserId().toString()))).header("Idempotency-Key", UUID.randomUUID())
                        .contentType(APPLICATION_JSON).content(body)).andReturn().getResponse().getStatus()));
                assertThatThrownBy(() -> pending.get().get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                return null;
            });
            assertThat(pending.get().get(15, TimeUnit.SECONDS)).isEqualTo(403);
        }
        assertThat(readChore(id, f.user).occurrence().occurrenceStatus()).isEqualTo(ChoreOccurrenceStatus.PENDING);
    }

    @Test void concurrentManagersCannotRemoveEachOtherAndLeaveNoAdministrator() throws Exception {
        var f = admin(); var second = person(f, Set.of(HOUSEHOLD_MEMBER_REMOVE, HOUSEHOLD_ROLE_UPDATE));
        var first = members.findById(f.member).orElseThrow();
        try (var pool = Executors.newFixedThreadPool(2)) {
            var gate = new CountDownLatch(1);
            var a = pool.submit(() -> { gate.await(); return remove(f, f.user, second, UUID.randomUUID()).andReturn().getResponse().getStatus(); });
            var b = pool.submit(() -> { gate.await(); return remove(f, second.getUserId(), first, UUID.randomUUID()).andReturn().getResponse().getStatus(); });
            gate.countDown();
            assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS))).containsExactlyInAnyOrder(200, 403);
        }
        assertThat(members.findAllByHousehold_HouseholdId(f.household)).hasSize(1);
    }

    @Test void concurrentRemovalAndRoleDemotionKeepAnAssignedAdministrator() throws Exception {
        var f = admin(); var second = person(f, Set.of(HOUSEHOLD_MEMBER_REMOVE, HOUSEHOLD_ROLE_UPDATE));
        try (var pool = Executors.newFixedThreadPool(2)) {
            var gate = new CountDownLatch(1);
            var a = pool.submit(() -> { gate.await(); return remove(f, f.user, second, UUID.randomUUID()).andReturn().getResponse().getStatus(); });
            var b = pool.submit(() -> { gate.await(); return mvc.perform(put(path(f)+"/roles/"+f.role)
                    .with(jwt().jwt(j -> j.subject(second.getUserId().toString()))).header("Idempotency-Key", UUID.randomUUID())
                    .contentType(APPLICATION_JSON).content(mapper.writeValueAsString(new UpdateHouseholdRoleRequest("Demoted", List.of(HOUSEHOLD_MEMBER_REMOVE), 0L))))
                    .andReturn().getResponse().getStatus(); });
            gate.countDown();
            var statuses = List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS));
            assertThat(statuses).contains(200);
            assertThat(statuses.stream().filter(s -> s == 200)).hasSize(1);
            assertThat(statuses).allMatch(s -> Set.of(200, 403, 409).contains(s));
        }
        assertThat(members.findAllByHousehold_HouseholdId(f.household)).anyMatch(m -> m.getHouseholdRole().getPermissions().stream()
                .anyMatch(p -> p.getName().equals(HOUSEHOLD_ROLE_UPDATE.name())));
    }

    private ResultActions remove(Fixture f, UUID actor, HouseholdMember target, UUID key) throws Exception {
        return mvc.perform(delete(path(f)+"/members/"+target.getHouseholdMemberId()).param("version", target.getVersion().toString())
                .with(jwt().jwt(j -> j.subject(actor.toString()))).header("Idempotency-Key", key));
    }
    private ResultActions review(ChoreResponse chore, UUID actor) throws Exception {
        var completion = chore.completions().getFirst();
        return mvc.perform(post("/api/v1/chores/"+chore.choreId()+"/completions/"+completion.choreCompletionId()+"/approve")
                .with(jwt().jwt(j -> j.subject(actor.toString()))).header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(new ChoreActionRequest(chore.version(), chore.occurrence().version(), completion.version()))));
    }
    private ChoreResponse complete(ChoreResponse chore, UUID actor) throws Exception {
        return decodeChore(mvc.perform(post("/api/v1/chores/"+chore.choreId()+"/occurrences/"+chore.occurrence().choreOccurrenceId()+"/complete")
                .with(jwt().jwt(j -> j.subject(actor.toString()))).header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(new ChoreActionRequest(chore.version(), chore.occurrence().version(), null))))
                .andExpect(status().isOk()).andReturn());
    }
    private ChoreResponse chore(Fixture f, HouseholdMember target, ChoreCreationPattern pattern, int approvals) throws Exception {
        var id = UUID.randomUUID();
        createChore.execute(new CreateChoreCommand(id, f.household, "History test", null, pattern,
                pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION ? ChoreRecurrenceUnit.DAY : null,
                1, pattern == ChoreCreationPattern.FIXED ? Instant.now().plusSeconds(60) : null,
                null, "Europe/Budapest", List.of(target.getHouseholdMemberId()), approvals,
                pattern == ChoreCreationPattern.ONCE ? null : UUID.randomUUID(), pattern == ChoreCreationPattern.ON_DEMAND ? null : UUID.randomUUID()), f.user);
        return readChore(id, target.getUserId());
    }
    private ChoreResponse readChore(UUID id, UUID user) throws Exception {
        return decodeChore(mvc.perform(get("/api/v1/chores/"+id).with(jwt().jwt(j -> j.subject(user.toString())))).andExpect(status().isOk()).andReturn());
    }
    private ChoreResponse decodeChore(MvcResult result) throws Exception { return mapper.readValue(result.getResponse().getContentAsString(), ChoreResponse.class); }
    private String path(Fixture f) { return "/api/v1/households/"+f.household; }
    private HouseholdMember person(Fixture f, Set<HouseholdPermission> grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Other", "Member")).getId();
        var role = new HouseholdRole(UUID.randomUUID(), f.household, "Role "+user.toString().substring(0, 8), false);
        grants.forEach(g -> role.getPermissions().add(permissions.findByName(g).orElseThrow()));
        roles.saveAndFlush(role);
        return members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), households.findById(f.household).orElseThrow(), user, role));
    }
    private Fixture admin() { return fixture(EnumSet.allOf(HouseholdPermission.class)); }
    private Fixture fixture(Set<HouseholdPermission> grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Role", "Manager")).getId();
        var home = UUID.randomUUID(); var role = UUID.randomUUID(); var member = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(home, "Home", null,
                List.of(new CreateHouseholdRoleCommand(role, "Administrator", grants)), role, member), user);
        return new Fixture(user, home, role, member);
    }
    private record Fixture(UUID user, UUID household, UUID role, UUID member) {}
}
