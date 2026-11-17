package hu.dncs.tracker.household.application.createhousehold;

import hu.dncs.tracker.household.application.exception.HouseholdCreatorNotFoundException;
import hu.dncs.tracker.household.application.exception.InvalidHouseholdRolesException;
import hu.dncs.tracker.household.application.repository.*;
import hu.dncs.tracker.identity.api.UserDirectory;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class CreateHouseholdUseCaseTests {
    private final HouseholdRepository households = mock(HouseholdRepository.class);
    private final HouseholdRoleRepository roles = mock(HouseholdRoleRepository.class);
    private final HouseholdMemberRepository members = mock(HouseholdMemberRepository.class);
    private final PermissionRepository permissions = mock(PermissionRepository.class);
    private final UserDirectory users = mock(UserDirectory.class);
    private final CreateHouseholdUseCase useCase = new CreateHouseholdUseCase(households, roles, members, permissions, users);
    private final UUID userId = UUID.randomUUID();
    private final UUID roleId = UUID.randomUUID();

    @Test
    void unknownCreatorCannotCreateAHousehold() {
        assertThrows(HouseholdCreatorNotFoundException.class, () -> useCase.execute(command(roleId), userId));
        verifyNoInteractions(households, roles, members, permissions);
    }

    @Test
    void creatorRoleMustBelongToTheSuppliedRoles() {
        when(users.userExists(userId)).thenReturn(true);
        assertThrows(InvalidHouseholdRolesException.class,
                () -> useCase.execute(command(UUID.randomUUID()), userId));
        verify(households, never()).save(any());
    }

    @Test
    void duplicateRoleNamesAreRejectedBeforeSaving() {
        when(users.userExists(userId)).thenReturn(true);
        var command = new CreateHouseholdCommand(UUID.randomUUID(), "Home", null,
                List.of(new CreateHouseholdRoleCommand(roleId, "Member", Set.of()),
                        new CreateHouseholdRoleCommand(UUID.randomUUID(), "Member", Set.of())),
                roleId, UUID.randomUUID());
        assertThrows(InvalidHouseholdRolesException.class, () -> useCase.execute(command, userId));
        verify(households, never()).save(any());
    }

    @Test
    void createsMembershipForAuthenticatedCreatorWithTheSelectedRole() {
        when(users.userExists(userId)).thenReturn(true);
        when(households.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(roles.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(members.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        var command = command(roleId);

        var result = useCase.execute(command, userId);

        assertEquals(command.householdId(), result.household().getHouseholdId());
        assertEquals(userId, result.household().getCreatedByUserId());
        assertEquals(command.householdMemberId(), result.creatorMembership().getHouseholdMemberId());
        assertEquals(userId, result.creatorMembership().getUserId());
        assertEquals(roleId, result.creatorMembership().getHouseholdRole().getHouseholdRoleId());
        assertEquals(1, result.roles().size());
        var saves = inOrder(households, roles, members);
        saves.verify(households).save(result.household());
        saves.verify(roles).saveAll(result.roles());
        saves.verify(members).save(result.creatorMembership());
    }

    private CreateHouseholdCommand command(UUID creatorRoleId) {
        return new CreateHouseholdCommand(UUID.randomUUID(), "Home", null,
                List.of(new CreateHouseholdRoleCommand(roleId, "Member", Set.of())),
                creatorRoleId, UUID.randomUUID());
    }
}
