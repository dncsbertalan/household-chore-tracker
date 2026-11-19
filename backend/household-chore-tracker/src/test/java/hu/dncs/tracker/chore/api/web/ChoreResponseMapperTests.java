package hu.dncs.tracker.chore.api.web;

import hu.dncs.tracker.chore.application.model.CreatedChore;
import hu.dncs.tracker.chore.domain.model.Chore;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import hu.dncs.tracker.identity.api.UserDirectory;
import hu.dncs.tracker.identity.api.UserInfo;
import org.junit.jupiter.api.Test;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class ChoreResponseMapperTests {
    @Test
    void assignedMembersAreResolvedAndBatchedAcrossChores() {
        var members = mock(HouseholdMemberRepository.class);
        var users = mock(UserDirectory.class);
        var userId = UUID.randomUUID();
        var household = new Household(UUID.randomUUID(), "Home", null, userId);
        var role = new HouseholdRole(UUID.randomUUID(), household.getHouseholdId(), "Member", false);
        var member = new HouseholdMember(UUID.randomUUID(), household, userId, role);
        var chore = mock(Chore.class);
        when(chore.getAssignedMemberIds()).thenReturn(Set.of(member.getHouseholdMemberId()));
        when(members.findAllById(List.of(member.getHouseholdMemberId()))).thenReturn(List.of(member));
        when(users.findUserInfoByIds(List.of(userId))).thenReturn(Map.of(userId, new UserInfo(userId, "test@example.com", "Test", "Member")));
        var created = new CreatedChore(chore, null, null);
        var result = new ChoreResponseMapper(members, users).from(List.of(created, created));
        assertThat(result).hasSize(2);
        assertThat(result.getFirst().assignedMembers().getFirst().firstName()).isEqualTo("Test");
        assertThat(result.getFirst().assignedMembers().getFirst().householdRole().name()).isEqualTo("Member");
        assertThat(result.getFirst().assignedMemberIds()).containsExactly(member.getHouseholdMemberId());
        verify(members, times(1)).findAllById(List.of(member.getHouseholdMemberId()));
        verify(users, times(1)).findUserInfoByIds(List.of(userId));
    }
}
