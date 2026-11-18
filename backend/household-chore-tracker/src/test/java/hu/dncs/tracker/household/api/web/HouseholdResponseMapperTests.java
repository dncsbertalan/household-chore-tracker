package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.createhousehold.CreateHouseholdResult;
import hu.dncs.tracker.household.application.model.*;
import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.domain.model.HouseholdRole;
import hu.dncs.tracker.identity.api.UserDirectory;
import hu.dncs.tracker.identity.api.UserInfo;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class HouseholdResponseMapperTests {
    private final UserDirectory users = mock(UserDirectory.class);
    private final hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository members = mock(hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository.class);
    private final HouseholdResponseMapper responses = new HouseholdResponseMapper(users, members);
    private final JsonMapper json = JsonMapper.builder().build();
    private final UserInfo ada = new UserInfo(UUID.randomUUID(), "ada@example.com", "Ada", "Lovelace");
    private final UserInfo grace = new UserInfo(UUID.randomUUID(), "grace@example.com", "Grace", "Hopper");

    @Test
    void everyResponseShapeIncludesTheFrontendUserInfoContract() {
        var household = household(ada.userId());
        var member = household.members().getFirst();
        when(users.findUserInfoByIds(List.of(ada.userId()))).thenReturn(Map.of(ada.userId(), ada));
        var created = responses.from(new CreateHouseholdResult(household.household(), household.roles(), member));
        var joined = responses.from(new JoinedHousehold(household.household(), household.roles(), member));
        var management = new HouseholdRoleManagement(household, List.of(),
                new HouseholdRoleManagement.Actions(true, false, false, false, false, false));
        var removed = responses.from(new HouseholdMemberRemoval(household.household().getHouseholdId(),
                UUID.randomUUID(), management), ada.userId());
        var members = List.of(created.creatorMembership(), created.members().getFirst(), joined.membership(),
                responses.from(household, ada.userId()).members().getFirst(),
                responses.from(management, ada.userId()).household().members().getFirst(),
                removed.management().household().members().getFirst());
        for (var response : members) {
            var node = json.readTree(json.writeValueAsString(response));
            assertThat(node.has("userInfo")).isFalse();
            assertThat(node.at("/userId").asString()).isEqualTo(ada.userId().toString());
            assertThat(node.at("/email").asString()).isEqualTo(ada.email());
            assertThat(node.at("/firstName").asString()).isEqualTo(ada.firstName());
            assertThat(node.at("/lastName").asString()).isEqualTo(ada.lastName());
            assertThat(node.path("userId").asString()).isEqualTo(ada.userId().toString());
        }
        assertThat(responses.from(new HouseholdMemberRemoval(household.household().getHouseholdId(),
                member.getHouseholdMemberId(), null), ada.userId()).management()).isNull();
    }

    @Test
    void listsBatchDistinctUsersAndMapEachProfileToItsMembership() {
        var households = List.of(household(ada.userId()), household(grace.userId()), household(ada.userId()));
        when(users.findUserInfoByIds(List.of(ada.userId(), grace.userId())))
                .thenReturn(Map.of(ada.userId(), ada, grace.userId(), grace));
        var second = households.get(1);
        var caller = new HouseholdMember(UUID.randomUUID(), second.household(), ada.userId(), second.roles().getFirst());
        when(members.findByHousehold_HouseholdIdAndUserId(second.household().getHouseholdId(), ada.userId()))
                .thenReturn(java.util.Optional.of(caller));
        var result = responses.from(households, ada.userId());
        assertThat(result.get(1).owner().userId()).isEqualTo(grace.userId());
        assertThat(result.get(1).me().userId()).isEqualTo(ada.userId());
        assertThat(result.stream().map(h -> h.members().getFirst().email()).toList())
                .containsExactly(ada.email(), grace.email(), ada.email());
        verify(users).findUserInfoByIds(List.of(ada.userId(), grace.userId()));
        verifyNoMoreInteractions(users);
    }

    @Test
    void summariesContainListFieldsAndBatchUserProfiles() {
        var first = household(ada.userId());
        var second = household(grace.userId());
        when(users.findUserInfoByIds(List.of(ada.userId(), grace.userId())))
                .thenReturn(Map.of(ada.userId(), ada, grace.userId(), grace));
        var result = responses.summaries(List.of(first, second, first));
        assertThat(result).hasSize(3);
        assertThat(result.getFirst().householdId()).isEqualTo(first.household().getHouseholdId());
        assertThat(result.getFirst().name()).isEqualTo("Home");
        assertThat(result.getFirst().description()).isNull();
        assertThat(result.stream().map(h -> h.members().getFirst().email()).toList())
                .containsExactly(ada.email(), grace.email(), ada.email());
        var node = json.readTree(json.writeValueAsString(result.getFirst()));
        assertThat(node.size()).isEqualTo(4);
        assertThat(node.has("members")).isTrue();
        verify(users).findUserInfoByIds(List.of(ada.userId(), grace.userId()));
        verifyNoMoreInteractions(users);
    }

    @Test
    void ownerIsIncludedWithoutExpandingPermissionFilteredMembers() {
        var owned = household(ada.userId());
        var owner = owned.members().getFirst();
        var caller = new HouseholdMember(UUID.randomUUID(), owned.household(), grace.userId(), owned.roles().getFirst());
        var restricted = new HouseholdDetails(owned.household(), owned.roles(), List.of(caller));
        when(members.findByHousehold_HouseholdIdAndUserId(owned.household().getHouseholdId(), ada.userId()))
                .thenReturn(java.util.Optional.of(owner));
        when(users.findUserInfoByIds(List.of(grace.userId(), ada.userId())))
                .thenReturn(Map.of(ada.userId(), ada, grace.userId(), grace));
        var response = responses.from(restricted, grace.userId());
        assertThat(response.members()).hasSize(1);
        assertThat(response.owner().userId()).isEqualTo(ada.userId());
        assertThat(response.me().userId()).isEqualTo(grace.userId());
    }

    private HouseholdDetails household(UUID userId) {
        var household = new Household(UUID.randomUUID(), "Home", null, userId);
        var role = new HouseholdRole(UUID.randomUUID(), household.getHouseholdId(), "Member", false);
        var member = new HouseholdMember(UUID.randomUUID(), household, userId, role);
        return new HouseholdDetails(household, List.of(role), List.of(member));
    }
}
