package hu.dncs.tracker;

import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import hu.dncs.tracker.chore.application.command.CreateChoreCommand;
import hu.dncs.tracker.chore.application.usecase.CreateChoreUseCase;
import hu.dncs.tracker.chore.domain.model.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import java.util.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration.class)
class OnlineResourceIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired HouseholdRepository households;
    @Autowired HouseholdRoleRepository roles;
    @Autowired HouseholdMemberRepository members;
    @Autowired PermissionRepository permissions;
    @Autowired CreateChoreUseCase createChore;
    @Autowired JdbcTemplate jdbc;
    @Autowired hu.dncs.tracker.identity.infrastructure.persistence.UserRepository users;

    // No test transaction: HTTP responses must map fully loaded entities with open-in-view disabled.
    @Test
    void householdQueriesAreAuthenticatedMembershipScopedAndIncludeCurrentGrants() throws Exception {
        var f = fixture(HOUSEHOLD_MEMBER_VIEW, HOUSEHOLD_ROLE_VIEW, CHORE_CREATE);
        var other = fixture(CHORE_CREATE);
        mvc.perform(get("/api/v1/households")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/households").with(jwt().jwt(j -> j.subject(f.user.toString()))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].householdId").value(f.household.getHouseholdId().toString()))
                .andExpect(jsonPath("$[0].members", hasSize(1)))
                .andExpect(jsonPath("$[0].members[0].householdRole.permissions[*].name", hasItem("CHORE_CREATE")));
        mvc.perform(get("/api/v1/households/" + f.household.getHouseholdId()).with(jwt().jwt(j -> j.subject(other.user.toString()))))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/households/" + f.household.getHouseholdId()).with(jwt().jwt(j -> j.subject(f.user.toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$.name").value("Home"));
    }

    @Test
    void restrictedMembersSeeOnlyTheirOwnMembershipAndRoleWhileInvitersSeeRoleCatalog() throws Exception {
        var f = fixture();
        var secondRole = roles.saveAndFlush(new HouseholdRole(UUID.randomUUID(), f.household.getHouseholdId(), "Other", false));
        members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), f.household, UUID.randomUUID(), secondRole));
        var path = "/api/v1/households/" + f.household.getHouseholdId();
        mvc.perform(get(path).with(jwt().jwt(j -> j.subject(f.user.toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$.members", hasSize(1)))
                .andExpect(jsonPath("$.roles", hasSize(1)));
        var inviter = UUID.randomUUID();
        var inviteRole = new HouseholdRole(UUID.randomUUID(), f.household.getHouseholdId(), "Inviter", false);
        inviteRole.getPermissions().add(permissions.findByName(HOUSEHOLD_MEMBER_INVITE).orElseThrow());
        inviteRole = roles.saveAndFlush(inviteRole);
        members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), f.household, inviter, inviteRole));
        mvc.perform(get(path).with(jwt().jwt(j -> j.subject(inviter.toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$.members", hasSize(1)))
                .andExpect(jsonPath("$.roles", hasSize(3)));
    }

    @Test
    void choreQueriesReturnCreatedScheduleAndAssignmentWithoutClientCatchUp() throws Exception {
        var f = fixture(CHORE_CREATE);
        var member = members.findByHousehold_HouseholdIdAndUserId(f.household.getHouseholdId(), f.user).orElseThrow();
        var id = UUID.randomUUID();
        createChore.execute(new CreateChoreCommand(id, f.household.getHouseholdId(), "Dishes", null,
                ChoreCreationPattern.ON_DEMAND, null, 1, null, null, "Europe/Budapest",
                List.of(member.getHouseholdMemberId()), 1, UUID.randomUUID(), null), f.user);
        var path = "/api/v1/households/" + f.household.getHouseholdId() + "/chores";
        mvc.perform(get(path).with(jwt().jwt(j -> j.subject(f.user.toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].choreId").value(id.toString()))
                .andExpect(jsonPath("$[0].schedule.scheduleType").value("ON_DEMAND"))
                .andExpect(jsonPath("$[0].assignedMemberIds[0]").value(member.getHouseholdMemberId().toString()))
                .andExpect(jsonPath("$[0].requiredApprovalCount").value(1));
        mvc.perform(get("/api/v1/chores").with(jwt().jwt(j -> j.subject(f.user.toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$", hasSize(1)));
        var stranger = UUID.randomUUID();
        mvc.perform(get(path).with(jwt().jwt(j -> j.subject(stranger.toString())))).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/chores").with(jwt().jwt(j -> j.subject(stranger.toString()))))
                .andExpect(status().isOk()).andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void obsoleteClientInfrastructureIsAbsentAfterMigration() throws Exception {
        for (var name : List.of("sync_entity_state", "sync_changes", "sync_sequence_state", "sync_snapshots", "sync_snapshot_items")) {
            assertThat(jdbc.queryForObject("select to_regclass(?)::text", String.class, name)).isNull();
        }
        assertThat(jdbc.queryForObject("select count(*) from flyway_schema_history where version = '5' and success", Integer.class)).isEqualTo(1);
        mvc.perform(get("/api/v1/sync/changes").with(jwt())).andExpect(status().isNotFound());
    }

    private Fixture fixture(HouseholdPermission... grants) {
        var user = users.saveAndFlush(new hu.dncs.tracker.identity.domain.model.User(
                UUID.randomUUID() + "@example.com", "Online", "Test")).getId();
        var household = households.saveAndFlush(new Household(UUID.randomUUID(), "Home", null, user));
        var role = new HouseholdRole(UUID.randomUUID(), household.getHouseholdId(), "Member", false);
        for (var grant : grants) role.getPermissions().add(permissions.findByName(grant).orElseThrow());
        role = roles.saveAndFlush(role);
        members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), household, user, role));
        return new Fixture(user, household);
    }
    private record Fixture(UUID user, Household household) {}
}
