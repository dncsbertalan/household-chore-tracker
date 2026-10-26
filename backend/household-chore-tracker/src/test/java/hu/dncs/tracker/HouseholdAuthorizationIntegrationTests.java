package hu.dncs.tracker;

import hu.dncs.tracker.household.application.HouseholdAuthorizationService;
import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import hu.dncs.tracker.household.domain.model.HouseholdRole;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRoleRepository;
import hu.dncs.tracker.household.infrastructure.persistence.PermissionRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestComponent;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.UUID;

import static hu.dncs.tracker.household.domain.model.HouseholdPermission.CHORE_CREATE;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.CHORE_DELETE;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "identity.tokens.secret=dGVzdC1vbmx5LXNpZ25pbmcta2V5LW5vdC1mb3ItcHJvZHVjdGlvbg==")
@AutoConfigureMockMvc
@Import({TestcontainersConfiguration.class, HouseholdAuthorizationIntegrationTests.ProtectedOperation.class})
@Transactional
class HouseholdAuthorizationIntegrationTests {
    @Autowired HouseholdAuthorizationService authorization;
    @Autowired HouseholdRepository households;
    @Autowired HouseholdRoleRepository roles;
    @Autowired HouseholdMemberRepository members;
    @Autowired PermissionRepository permissions;
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;

    @Test
    void memberCanCreateChoresOnlyWithTheMatchingRoleGrant() {
        var userId = UUID.randomUUID();
        var household = household(UUID.randomUUID());
        membership(household, userId, role(household, false, CHORE_CREATE));

        assertThat(authorization.hasPermission(household.getHouseholdId(), userId, CHORE_CREATE)).isTrue();
        assertThatCode(() -> authorization.requirePermission(household.getHouseholdId(), userId, CHORE_CREATE))
                .doesNotThrowAnyException();
        assertThat(authorization.hasPermission(household.getHouseholdId(), userId, CHORE_DELETE)).isFalse();
    }

    @Test
    void creatorAndSystemRoleDoNotBypassMissingGrants() {
        var creatorId = UUID.randomUUID();
        var household = household(creatorId);
        membership(household, creatorId, role(household, true, CHORE_DELETE));

        assertDenied(household.getHouseholdId(), creatorId);
    }

    @Test
    void creatorWithoutMembershipHasNoAccess() {
        var creatorId = UUID.randomUUID();
        var household = household(creatorId);
        role(household, false, CHORE_CREATE);

        assertDenied(household.getHouseholdId(), creatorId);
    }

    @Test
    void grantsInAnotherHouseholdDoNotApply() {
        var userId = UUID.randomUUID();
        var first = household(UUID.randomUUID());
        var second = household(UUID.randomUUID());
        membership(first, userId, role(first, false, CHORE_CREATE));
        membership(second, userId, role(second, false, CHORE_DELETE));

        assertDenied(second.getHouseholdId(), userId);
    }

    @Test
    void roleFromAnotherHouseholdCannotGrantAccessThroughInconsistentMembership() {
        var userId = UUID.randomUUID();
        var first = household(UUID.randomUUID());
        var second = household(UUID.randomUUID());
        var member = membership(first, userId, role(first, false));
        var foreignRole = role(second, false, CHORE_CREATE);
        jdbc.update("UPDATE household_member SET household_role_id = ? WHERE household_member_id = ?",
                foreignRole.getHouseholdRoleId(), member.getHouseholdMemberId());

        assertDenied(first.getHouseholdId(), userId);
    }

    @Test
    void revokingAGrantTakesEffectOnTheNextCheck() {
        var userId = UUID.randomUUID();
        var household = household(UUID.randomUUID());
        var role = role(household, false, CHORE_CREATE);
        membership(household, userId, role);
        assertThat(authorization.hasPermission(household.getHouseholdId(), userId, CHORE_CREATE)).isTrue();

        role.getPermissions().clear();
        roles.flush();

        assertDenied(household.getHouseholdId(), userId);
    }

    @Test
    void removingMembershipTakesEffectOnTheNextCheck() {
        var userId = UUID.randomUUID();
        var household = household(UUID.randomUUID());
        var member = membership(household, userId, role(household, false, CHORE_CREATE));
        assertThat(authorization.hasPermission(household.getHouseholdId(), userId, CHORE_CREATE)).isTrue();

        members.delete(member);
        members.flush();

        assertDenied(household.getHouseholdId(), userId);
    }

    @Test
    void unknownHouseholdIsDenied() {
        assertDenied(UUID.randomUUID(), UUID.randomUUID());
    }

    @Test
    void authenticatedCallerGetsForbiddenWithoutTheGrantAndSucceedsWithIt() throws Exception {
        var userId = UUID.randomUUID();
        var household = household(UUID.randomUUID());
        membership(household, userId, role(household, false, CHORE_CREATE));
        var path = "/_test/households/" + household.getHouseholdId() + "/chore-create";

        mvc.perform(get(path)).andExpect(status().isUnauthorized());
        mvc.perform(get(path).with(jwt().jwt(jwt -> jwt.subject(UUID.randomUUID().toString()))))
                .andExpect(status().isForbidden());
        mvc.perform(get(path).with(jwt().jwt(jwt -> jwt.subject(userId.toString()))))
                .andExpect(status().isNoContent());
    }

    @Test
    void migratedCatalogMatchesEveryEnumName() {
        assertThat(permissions.findAll()).extracting(permission -> permission.getName())
                .containsExactlyInAnyOrderElementsOf(Arrays.stream(HouseholdPermission.values())
                        .map(Enum::name).toList());
    }

    private void assertDenied(UUID householdId, UUID userId) {
        assertThat(authorization.hasPermission(householdId, userId, CHORE_CREATE)).isFalse();
        assertThatThrownBy(() -> authorization.requirePermission(householdId, userId, CHORE_CREATE))
                .isInstanceOf(AccessDeniedException.class);
    }

    private Household household(UUID creatorId) {
        return households.saveAndFlush(new Household(UUID.randomUUID(), "Home", null, creatorId));
    }

    private HouseholdRole role(Household household, boolean systemRole, HouseholdPermission... grants) {
        var role = new HouseholdRole(UUID.randomUUID(), household.getHouseholdId(), "Member", systemRole);
        for (var grant : grants) {
            role.getPermissions().add(permissions.findByName(grant).orElseThrow());
        }
        return roles.saveAndFlush(role);
    }

    private HouseholdMember membership(Household household, UUID userId, HouseholdRole role) {
        return members.saveAndFlush(new HouseholdMember(UUID.randomUUID(), household, userId, role));
    }

    /** Test-only adapter verifies Spring Security's HTTP mapping without adding a production endpoint. */
    @TestComponent
    @RestController
    static class ProtectedOperation {
        private final HouseholdAuthorizationService authorization;

        ProtectedOperation(HouseholdAuthorizationService authorization) {
            this.authorization = authorization;
        }

        @GetMapping("/_test/households/{householdId}/chore-create")
        ResponseEntity<Void> check(@PathVariable UUID householdId, Authentication authentication) {
            authorization.requirePermission(householdId, UUID.fromString(authentication.getName()), CHORE_CREATE);
            return ResponseEntity.noContent().build();
        }
    }
}
