package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.model.*;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.identity.api.UserInfo;
import hu.dncs.tracker.identity.api.UserLookup;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class HouseholdResponseMapperTests {
    private final UserLookup users = mock(UserLookup.class);
    private final HouseholdResponseMapper responses = new HouseholdResponseMapper(users);
    private final JsonMapper json = JsonMapper.builder().build();
    private final UserInfo ada = new UserInfo(UUID.randomUUID(), "ada@example.com", "Ada", "Lovelace");
    private final UserInfo grace = new UserInfo(UUID.randomUUID(), "grace@example.com", "Grace", "Hopper");

    @Test
    void everyResponseShapeIncludesTheFrontendUserInfoContract() {
        var household = household(ada.userId());
        var member = household.members().getFirst();
        when(users.findUserInfoByIds(List.of(ada.userId()))).thenReturn(Map.of(ada.userId(), ada));
        var created = responses.from(new CreatedHousehold(household.household(), household.roles(), member));
        var joined = responses.from(new JoinedHousehold(household.household(), household.roles(), member));
        var management = new HouseholdRoleManagement(household, List.of(),
                new HouseholdRoleManagement.Actions(true, false, false, false, false, false));
        var removed = responses.from(new HouseholdMemberRemoval(household.household().getHouseholdId(),
                UUID.randomUUID(), management));
        var members = List.of(created.creatorMembership(), created.members().getFirst(), joined.membership(),
                responses.from(household).members().getFirst(),
                responses.from(management).household().members().getFirst(),
                removed.management().household().members().getFirst());
        for (var response : members) {
            var node = json.readTree(json.writeValueAsString(response));
            assertThat(node.path("userInfo").size()).isEqualTo(4);
            assertThat(node.at("/userInfo/userId").asString()).isEqualTo(ada.userId().toString());
            assertThat(node.at("/userInfo/email").asString()).isEqualTo(ada.email());
            assertThat(node.at("/userInfo/firstName").asString()).isEqualTo(ada.firstName());
            assertThat(node.at("/userInfo/lastName").asString()).isEqualTo(ada.lastName());
            assertThat(node.path("userId").asString()).isEqualTo(ada.userId().toString());
        }
        assertThat(responses.from(new HouseholdMemberRemoval(household.household().getHouseholdId(),
                member.getHouseholdMemberId(), null)).management()).isNull();
    }

    @Test
    void listsBatchDistinctUsersAndMapEachProfileToItsMembership() {
        var households = List.of(household(ada.userId()), household(grace.userId()), household(ada.userId()));
        when(users.findUserInfoByIds(List.of(ada.userId(), grace.userId())))
                .thenReturn(Map.of(ada.userId(), ada, grace.userId(), grace));
        var result = responses.from(households);
        assertThat(result.stream().map(h -> h.members().getFirst().userInfo()).toList())
                .containsExactly(ada, grace, ada);
        verify(users).findUserInfoByIds(List.of(ada.userId(), grace.userId()));
        verifyNoMoreInteractions(users);
    }

    private HouseholdDetails household(UUID userId) {
        var household = new Household(UUID.randomUUID(), "Home", null, userId);
        var role = new HouseholdRole(UUID.randomUUID(), household.getHouseholdId(), "Member", false);
        var member = new HouseholdMember(UUID.randomUUID(), household, userId, role);
        return new HouseholdDetails(household, List.of(role), List.of(member));
    }
}
