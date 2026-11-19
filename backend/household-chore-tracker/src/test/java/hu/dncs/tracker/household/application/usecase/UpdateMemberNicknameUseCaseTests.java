package hu.dncs.tracker.household.application.usecase;

import hu.dncs.tracker.household.application.command.UpdateMemberNicknameCommand;
import hu.dncs.tracker.household.application.exception.HouseholdRoleManagementException;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;
import java.util.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class UpdateMemberNicknameUseCaseTests {
    final HouseholdRepository households = mock(HouseholdRepository.class);
    final HouseholdMemberRepository members = mock(HouseholdMemberRepository.class);
    final UpdateMemberNicknameUseCase service = new UpdateMemberNicknameUseCase(households, members);
    final UUID caller = UUID.randomUUID();
    final Household household = new Household(UUID.randomUUID(), "Home", null, caller);
    final HouseholdRole role = new HouseholdRole(UUID.randomUUID(), household.getHouseholdId(), "Member", false);
    final HouseholdMember target = new HouseholdMember(UUID.randomUUID(), household, UUID.randomUUID(), role);

    void setup(boolean authorized) {
        ReflectionTestUtils.setField(target, "version", 1L);
        when(households.findForUpdate(household.getHouseholdId())).thenReturn(Optional.of(household));
        when(members.findByHousehold_HouseholdIdAndUserId(household.getHouseholdId(), caller))
                .thenReturn(authorized ? Optional.of(new HouseholdMember(UUID.randomUUID(), household, caller, role)) : Optional.empty());
        when(members.findAllByHousehold_HouseholdId(household.getHouseholdId())).thenReturn(List.of(target));
    }
    @Test void anyActiveMemberCanRenameAndClearAnotherMemberWithoutPermissions() {
        setup(true);
        service.execute(household.getHouseholdId(), target.getHouseholdMemberId(), new UpdateMemberNicknameCommand("  Nick  ", 1L), caller);
        assertThat(target.getNickname()).isEqualTo("Nick");
        service.execute(household.getHouseholdId(), target.getHouseholdMemberId(), new UpdateMemberNicknameCommand(" ", 1L), caller);
        assertThat(target.getNickname()).isNull();
        verify(members, times(2)).flush();
    }
    @Test void nonMembersCannotEdit() {
        setup(false);
        assertThatThrownBy(() -> service.execute(household.getHouseholdId(), target.getHouseholdMemberId(), new UpdateMemberNicknameCommand("Nick", 1L), caller))
                .isInstanceOf(AccessDeniedException.class);
        verify(members, never()).flush();
    }
    @Test void rejectsStaleVersionAndOverlongNames() {
        setup(true);
        assertThatThrownBy(() -> service.execute(household.getHouseholdId(), target.getHouseholdMemberId(), new UpdateMemberNicknameCommand("Nick", 0L), caller))
                .isInstanceOf(HouseholdRoleManagementException.class);
        assertThatThrownBy(() -> service.execute(household.getHouseholdId(), target.getHouseholdMemberId(), new UpdateMemberNicknameCommand("a".repeat(101), 1L), caller))
                .isInstanceOf(HouseholdRoleManagementException.class);
        verify(members, never()).flush();
    }
}
