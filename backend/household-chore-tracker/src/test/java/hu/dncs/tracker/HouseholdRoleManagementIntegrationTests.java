package hu.dncs.tracker;

import hu.dncs.tracker.household.api.web.request.*;
import hu.dncs.tracker.household.api.web.response.*;
import hu.dncs.tracker.household.application.command.*;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
import hu.dncs.tracker.household.application.HouseholdInvitationService;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import hu.dncs.tracker.chore.application.usecase.CreateChoreUseCase;
import hu.dncs.tracker.chore.application.command.CreateChoreCommand;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.chore.api.web.request.ChoreActionRequest;
import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.*;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.ObjectMapper;
import java.util.*;
import java.util.concurrent.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class HouseholdRoleManagementIntegrationTests {
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
    @Autowired JdbcTemplate jdbc;

    @Test void roleEditorCanGrantTheNewPermissionAndThenApproveTheirPendingCompletion() throws Exception {
        var f = admin();
        var original = read(f);
        var userInfo = original.household().members().getFirst().userInfo();
        var account = users.findById(f.user).orElseThrow();
        assertThat(userInfo.userId()).isEqualTo(f.user);
        assertThat(userInfo.email()).isEqualTo(account.getEmail());
        assertThat(userInfo.firstName()).isEqualTo(account.getFirstName());
        assertThat(userInfo.lastName()).isEqualTo(account.getLastName());
        assertThat(original.permissions()).extracting(PermissionResponse::name).contains("CHORE_SELF_APPROVE_COMPLETION");
        assertThat(role(original, f.role).permissions()).extracting(PermissionResponse::name).doesNotContain("CHORE_SELF_APPROVE_COMPLETION");
        var choreId = UUID.randomUUID();
        var created = createChore.execute(new CreateChoreCommand(choreId, f.household, "Test", null, ChoreCreationPattern.ONCE,
                null, 1, null, null, "Europe/Budapest", List.of(f.member), 1, null, UUID.randomUUID()), f.user);
        var chore = readChore(f, choreId);
        var pending = mapper.readValue(mvc.perform(post("/api/v1/chores/" + choreId + "/occurrences/" + created.occurrence().getChoreOccurrenceId() + "/complete")
                .with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .contentType(APPLICATION_JSON).content(mapper.writeValueAsString(new ChoreActionRequest(chore.version(), chore.occurrence().version(), null))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(), ChoreResponse.class);
        assertThat(pending.actions().canApprove()).isFalse();
        var target = role(original, f.role);
        var grants = new ArrayList<>(target.permissions().stream().map(p -> HouseholdPermission.valueOf(p.name())).toList());
        grants.add(CHORE_SELF_APPROVE_COMPLETION);
        var updated = decode(update(f, f.user, target, "Administrator", grants).andExpect(status().isOk()).andReturn());
        assertThat(role(updated, f.role).version()).isGreaterThan(target.version());
        assertThat(updated.household().members().getFirst().householdRole().permissions()).extracting(PermissionResponse::name)
                .contains("CHORE_SELF_APPROVE_COMPLETION");
        var allowed = readChore(f, choreId);
        assertThat(allowed.actions().canApprove()).isTrue();
        mvc.perform(post("/api/v1/chores/" + choreId + "/completions/" + allowed.completions().getFirst().choreCompletionId() + "/approve")
                .with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .contentType(APPLICATION_JSON).content(mapper.writeValueAsString(new ChoreActionRequest(allowed.version(), allowed.occurrence().version(), allowed.completions().getFirst().version()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$.occurrence.occurrenceStatus").value("COMPLETED"));
    }

    @Test void viewGrantNeverAuthorizesAnyMutationAndCreatorIdentityDoesNotBypassGrants() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_ROLE_VIEW));
        var data = read(f);
        assertThat(data.actions().canUpdate()).isFalse();
        var target = role(data, f.role);
        update(f, f.user, target, "Changed", List.of(HOUSEHOLD_ROLE_VIEW)).andExpect(status().isForbidden());
        create(f, "New", List.of(CHORE_COMPLETE), UUID.randomUUID()).andExpect(status().isForbidden());
        delete(f, target).andExpect(status().isForbidden());
        assign(f, f.member, target.householdRoleId(), 0L, target.version()).andExpect(status().isForbidden());
        var denied = fixture(Set.of());
        mvc.perform(get(path(denied)).with(jwt().jwt(j -> j.subject(denied.user.toString())))).andExpect(status().isForbidden());
        mvc.perform(get(path(f))).andExpect(status().isUnauthorized());
    }

    @Test void createUpdateDeleteAndAssignmentUseSeparateGrants() throws Exception {
        var f = fixture(Set.of(HOUSEHOLD_ROLE_CREATE));
        var response = decode(create(f, " New role ", List.of(CHORE_SELF_APPROVE_COMPLETION), UUID.randomUUID())
                .andExpect(status().isCreated()).andReturn());
        var target = response.household().roles().stream().filter(r -> r.name().equals("New role")).findFirst().orElseThrow();
        update(f, f.user, target, "Cannot edit", List.of()).andExpect(status().isForbidden());
        delete(f, target).andExpect(status().isForbidden());
        assign(f, f.member, target.householdRoleId(), 0L, target.version()).andExpect(status().isForbidden());
        var editor = fixture(Set.of(HOUSEHOLD_ROLE_UPDATE));
        var own = role(read(editor), editor.role);
        create(editor, "No create", List.of(), UUID.randomUUID()).andExpect(status().isForbidden());
        delete(editor, own).andExpect(status().isForbidden());
        assign(editor, editor.member, own.householdRoleId(), 0L, own.version()).andExpect(status().isForbidden());
    }

    @Test void scopedIdsCannotModifyAnotherHouseholdsRolesOrMembers() throws Exception {
        var f = admin(); var other = admin();
        var foreign = role(read(other), other.role);
        update(f, f.user, foreign, "Foreign", List.of()).andExpect(status().isNotFound());
        delete(f, foreign).andExpect(status().isNotFound());
        assign(f, other.member, f.role, 0L, 0L).andExpect(status().isNotFound());
        assign(f, f.member, other.role, 0L, 0L).andExpect(status().isNotFound());
        assertThat(role(read(other), other.role).name()).isEqualTo(foreign.name());
    }

    @Test void lastManagerCannotBeRemovedThroughPermissionsOrMembershipChanges() throws Exception {
        var f = admin(); var before = read(f); var manager = role(before, f.role);
        update(f, f.user, manager, manager.name(), List.of(CHORE_COMPLETE)).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_role_last_manager"));
        var plain = extraRole(f, "Plain", false, Set.of());
        assign(f, f.member, plain.getHouseholdRoleId(), 0L, plain.getVersion()).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_role_last_manager"));
        assertThat(role(read(f), f.role).permissions()).isEqualTo(manager.permissions());
        assertThat(members.findById(f.member).orElseThrow().getHouseholdRole().getHouseholdRoleId()).isEqualTo(f.role);
    }

    @Test void selfDemotionSucceedsWithAnotherManagerAndImmediatelyReturnsReducedAccess() throws Exception {
        var f = admin();
        extraMember(f, roles.findAllByHouseholdIdOrderByCreatedAtAscHouseholdRoleIdAsc(f.household).stream().filter(r -> r.getHouseholdRoleId().equals(f.role)).findFirst().orElseThrow());
        var plain = extraRole(f, "Plain", false, Set.of());
        var result = decode(assign(f, f.member, plain.getHouseholdRoleId(), 0L, plain.getVersion()).andExpect(status().isOk()).andReturn());
        assertThat(result.actions().canView()).isFalse();
        assertThat(result.permissions()).isEmpty();
        assertThat(result.household().members().getFirst().householdRole().householdRoleId()).isEqualTo(plain.getHouseholdRoleId());
        mvc.perform(get(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))).andExpect(status().isForbidden());
        create(f, "Denied after demotion", List.of(), UUID.randomUUID()).andExpect(status().isForbidden());
    }

    @Test void systemAndReferencedRolesCannotBeDeletedAndUnusedRolesCan() throws Exception {
        var f = admin();
        var system = extraRole(f, "System", true, Set.of(CHORE_COMPLETE));
        var systemDto = role(read(f), system.getHouseholdRoleId());
        update(f, f.user, systemDto, "Renamed", List.of()).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_role_system_role"));
        delete(f, systemDto).andExpect(status().isConflict());
        delete(f, role(read(f), f.role)).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("household_role_in_use"));
        var referenced = extraRole(f, "Invited", false, Set.of());
        var invitation = invitations.invite(f.household, new InviteHouseholdMemberCommand(UUID.randomUUID()+"@test.invalid", referenced.getHouseholdRoleId()), f.user);
        invitations.revoke(f.household, invitation.householdInvitationId(), f.user);
        delete(f, role(read(f), referenced.getHouseholdRoleId())).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("household_role_in_use"));
        var unused = extraRole(f, "Unused", false, Set.of(CHORE_COMPLETE));
        var result = decode(delete(f, role(read(f), unused.getHouseholdRoleId())).andExpect(status().isOk()).andReturn());
        assertThat(result.household().roles()).extracting(HouseholdRoleResponse::householdRoleId).doesNotContain(unused.getHouseholdRoleId());
    }

    @Test void assignmentsReturnAuthoritativeMembershipAndRejectStaleMemberOrRoleVersions() throws Exception {
        var f = admin();
        var person = extraMember(f, extraRole(f, "Basic", false, Set.of(CHORE_COMPLETE)));
        var target = extraRole(f, "Approver", false, Set.of(CHORE_APPROVE_COMPLETION, CHORE_SELF_APPROVE_COMPLETION));
        var updated = decode(assign(f, person.getHouseholdMemberId(), target.getHouseholdRoleId(), person.getVersion(), target.getVersion())
                .andExpect(status().isOk()).andReturn());
        var assigned = updated.household().members().stream().filter(m -> m.householdMemberId().equals(person.getHouseholdMemberId())).findFirst().orElseThrow();
        assertThat(assigned.householdRole().householdRoleId()).isEqualTo(target.getHouseholdRoleId());
        assertThat(assigned.version()).isGreaterThan(person.getVersion());
        assign(f, person.getHouseholdMemberId(), f.role, person.getVersion(), 0L).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_role_stale"));
        var snapshot = role(read(f), target.getHouseholdRoleId());
        update(f, f.user, snapshot, "Changed", List.of(CHORE_COMPLETE)).andExpect(status().isOk());
        assign(f, person.getHouseholdMemberId(), target.getHouseholdRoleId(), assigned.version(), snapshot.version())
                .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("household_role_stale"));
    }

    @Test void staleRoleEditsDoNotOverwriteAnotherEditorsChanges() throws Exception {
        var f = admin();
        var created = extraRole(f, "Target", false, Set.of());
        var target = role(read(f), created.getHouseholdRoleId());
        update(f, f.user, target, "First edit", List.of(CHORE_COMPLETE)).andExpect(status().isOk());
        update(f, f.user, target, "Stale edit", List.of()).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_role_stale"));
        assertThat(role(read(f), target.householdRoleId()).name()).isEqualTo("First edit");
    }

    @ParameterizedTest @ValueSource(strings = {"", "  ", "\u00a0\u200b", "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"})
    void invalidNamesNeverCreateRoles(String name) throws Exception {
        var f = admin();
        var count = read(f).household().roles().size();
        create(f, name, List.of(CHORE_COMPLETE), UUID.randomUUID()).andExpect(status().isBadRequest());
        assertThat(read(f).household().roles()).hasSize(count);
    }

    @Test void duplicateNamesAndDuplicateOrUnknownPermissionsAreRejected() throws Exception {
        var f = admin();
        extraRole(f, "Member", false, Set.of());
        create(f, " member ", List.of(), UUID.randomUUID()).andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("household_role_duplicate_name"));
        create(f, "Duplicate permissions", List.of(CHORE_COMPLETE, CHORE_COMPLETE), UUID.randomUUID()).andExpect(status().isBadRequest());
        mvc.perform(post(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .contentType(APPLICATION_JSON).content("{\"name\":\"Forged\",\"permissions\":[\"UNKNOWN_GRANT\"]}"))
                .andExpect(status().isBadRequest());
    }

    @Test void missingOrNegativeVersionsAndNullPermissionsAreRejectedBeforeChanges() throws Exception {
        var f = admin();
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete(path(f)+"/"+f.role).param("version", "-1")
                .with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID()))
                .andExpect(status().isBadRequest());
        mvc.perform(put(path(f)+"/"+f.role).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .contentType(APPLICATION_JSON).content("{\"name\":\"Forged\",\"permissions\":[],\"version\":-1}"))
                .andExpect(status().isBadRequest());
        mvc.perform(put(path(f)+"/"+f.role).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .contentType(APPLICATION_JSON).content("{\"name\":\"Forged\",\"permissions\":[]}"))
                .andExpect(status().isBadRequest());
        create(f, "Missing permissions", null, UUID.randomUUID()).andExpect(status().isBadRequest());
        assertThat(role(read(f), f.role).name()).isEqualTo("Administrator");
    }

    @Test void unchangedCreateRetriesDoNotCreateDuplicateRoles() throws Exception {
        var f = admin(); var key = UUID.randomUUID();
        var first = create(f, "Reliable create", List.of(CHORE_SELF_APPROVE_COMPLETION), key).andExpect(status().isCreated()).andReturn();
        var replay = create(f, "Reliable create", List.of(CHORE_SELF_APPROVE_COMPLETION), key).andExpect(status().isCreated()).andReturn();
        assertThat(replay.getResponse().getContentAsString()).isEqualTo(first.getResponse().getContentAsString());
        assertThat(read(f).household().roles().stream().filter(r -> r.name().equals("Reliable create"))).hasSize(1);
    }

    @Test void concurrentManagersCannotRevokeEachOthersAuthorityAfterItHasBeenRemoved() throws Exception {
        var f = admin();
        var secondRole = extraRole(f, "Second manager", false, Set.of(HOUSEHOLD_ROLE_UPDATE, HOUSEHOLD_ROLE_VIEW));
        var second = extraMember(f, secondRole);
        var firstRole = role(read(f), f.role);
        var secondDto = role(read(f), secondRole.getHouseholdRoleId());
        try (var pool = Executors.newFixedThreadPool(2)) {
            var gate = new CountDownLatch(1);
            var a = pool.submit(() -> { gate.await(); return update(f, f.user, secondDto, "Second manager", List.of(HOUSEHOLD_ROLE_VIEW)).andReturn().getResponse().getStatus(); });
            var b = pool.submit(() -> { gate.await(); return update(f, second.getUserId(), firstRole, "Administrator", List.of(HOUSEHOLD_ROLE_VIEW)).andReturn().getResponse().getStatus(); });
            gate.countDown();
            assertThat(List.of(a.get(15, TimeUnit.SECONDS), b.get(15, TimeUnit.SECONDS))).containsExactlyInAnyOrder(200, 403);
        }
        assertThat(jdbc.queryForObject("""
            select count(*) from household_member m join household_role_permission rp on rp.household_role_id=m.household_role_id
            join permission p on p.permission_id=rp.permission_id where m.household_id=? and p.name='HOUSEHOLD_ROLE_UPDATE'
            """, Integer.class, f.household)).isEqualTo(1);
    }

    private HouseholdRolesResponse read(Fixture f) throws Exception {
        return decode(mvc.perform(get(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString())))).andExpect(status().isOk()).andReturn());
    }
    private HouseholdRolesResponse decode(MvcResult result) throws Exception { return mapper.readValue(result.getResponse().getContentAsString(), HouseholdRolesResponse.class); }
    private HouseholdRoleResponse role(HouseholdRolesResponse data, UUID id) { return data.household().roles().stream().filter(r -> r.householdRoleId().equals(id)).findFirst().orElseThrow(); }
    private String path(Fixture f) { return "/api/v1/households/" + f.household + "/roles"; }
    private ResultActions create(Fixture f, String name, List<HouseholdPermission> grants, UUID key) throws Exception {
        return mvc.perform(post(path(f)).with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", key)
                .contentType(APPLICATION_JSON).content(mapper.writeValueAsString(new SaveHouseholdRoleRequest(name, grants))));
    }
    private ResultActions update(Fixture f, UUID actor, HouseholdRoleResponse role, String name, List<HouseholdPermission> grants) throws Exception {
        return mvc.perform(put(path(f)+"/"+role.householdRoleId()).with(jwt().jwt(j -> j.subject(actor.toString()))).header("Idempotency-Key", UUID.randomUUID())
                .contentType(APPLICATION_JSON).content(mapper.writeValueAsString(new UpdateHouseholdRoleRequest(name, grants, role.version()))));
    }
    private ResultActions delete(Fixture f, HouseholdRoleResponse role) throws Exception {
        return mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete(path(f)+"/"+role.householdRoleId()).param("version", role.version().toString())
                .with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID()));
    }
    private ResultActions assign(Fixture f, UUID member, UUID role, Long memberVersion, Long roleVersion) throws Exception {
        return mvc.perform(put("/api/v1/households/"+f.household+"/members/"+member+"/role")
                .with(jwt().jwt(j -> j.subject(f.user.toString()))).header("Idempotency-Key", UUID.randomUUID()).contentType(APPLICATION_JSON)
                .content(mapper.writeValueAsString(new AssignHouseholdRoleRequest(role, memberVersion, roleVersion))));
    }
    private ChoreResponse readChore(Fixture f, UUID id) throws Exception {
        return mapper.readValue(mvc.perform(get("/api/v1/chores/"+id).with(jwt().jwt(j -> j.subject(f.user.toString()))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString(), ChoreResponse.class);
    }
    private HouseholdRole extraRole(Fixture f, String name, boolean system, Set<HouseholdPermission> grants) {
        var role = new HouseholdRole(UUID.randomUUID(), f.household, name, system);
        for (var grant : grants) role.getPermissions().add(permissions.findByName(grant).orElseThrow());
        return roles.saveAndFlush(role);
    }
    private HouseholdMember extraMember(Fixture f, HouseholdRole role) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Other", "Member")).getId();
        return members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), households.findById(f.household).orElseThrow(), user, role));
    }
    private Fixture admin() {
        var grants = EnumSet.allOf(HouseholdPermission.class); grants.remove(CHORE_SELF_APPROVE_COMPLETION);
        return fixture(grants);
    }
    private Fixture fixture(Set<HouseholdPermission> grants) {
        var user = users.saveAndFlush(new User(UUID.randomUUID()+"@test.invalid", "Role", "Manager")).getId();
        var household = UUID.randomUUID(); var role = UUID.randomUUID(); var member = UUID.randomUUID();
        createHousehold.execute(new CreateHouseholdCommand(household, "Home", null,
                List.of(new CreateHouseholdRoleCommand(role, "Administrator", grants)), role, member), user);
        return new Fixture(user, household, role, member);
    }
    private record Fixture(UUID user, UUID household, UUID role, UUID member) {}
}
