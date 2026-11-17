package hu.dncs.tracker.household.application.createhousehold;

import hu.dncs.tracker.household.application.exception.HouseholdAlreadyExistsException;
import hu.dncs.tracker.household.application.exception.HouseholdCreationConflictException;
import hu.dncs.tracker.household.application.exception.HouseholdCreatorNotFoundException;
import hu.dncs.tracker.household.application.exception.InvalidHouseholdRolesException;
import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.domain.model.HouseholdRole;
import hu.dncs.tracker.household.application.repository.*;
import hu.dncs.tracker.identity.api.UserDirectory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
@RequiredArgsConstructor
public class CreateHouseholdUseCase {
    private final HouseholdRepository households;
    private final HouseholdRoleRepository householdRoles;
    private final HouseholdMemberRepository members;
    private final PermissionRepository permissions;
    private final UserDirectory userDirectory;

    @Transactional
    public CreateHouseholdResult execute(CreateHouseholdCommand command, UUID authenticatedUserId) {
        if (!userDirectory.userExists(authenticatedUserId)) {
            throw new HouseholdCreatorNotFoundException();
        }

        if (households.existsById(command.householdId())) {
            throw new HouseholdAlreadyExistsException();
        }

        validateRoles(command);

        if (command.householdMemberId() == null) {
            throw new InvalidHouseholdRolesException("HouseholdMemberId is required.");
        }

        if (members.existsById(command.householdMemberId()) ||
                householdRoles.anyExistsById(command.roles().stream().map(CreateHouseholdRoleCommand::householdRoleId).toList())) {
            throw new HouseholdCreationConflictException();
        }

        var household = new Household(command.householdId(), command.name(), command.description(), authenticatedUserId);

        household = households.save(household);
        var roles = householdRoles.saveAll(createRoles(command, household));
        var creatorRole = roles.stream()
                .filter(role -> role.getHouseholdRoleId().equals(command.creatorRoleId()))
                .findFirst()
                .orElseThrow();
        var membership = new HouseholdMember(command.householdMemberId(), household, authenticatedUserId, creatorRole);
        membership = members.save(membership);
        return new CreateHouseholdResult(household, roles, membership);
    }

    private List<HouseholdRole> createRoles(CreateHouseholdCommand command, Household household) {
        var roles = new ArrayList<HouseholdRole>();
        for (var requestedRole : command.roles()) {
            var role = new HouseholdRole(requestedRole.householdRoleId(), household.getHouseholdId(), requestedRole.name(), false);

            for (var permissionName : requestedRole.permissions()) {
                role.getPermissions().add(permissions.findByName(permissionName)
                        .orElseThrow(() -> new IllegalStateException("Missing seeded permission: " + permissionName)));
            }

            roles.add(role);
        }
        return roles;
    }

    private void validateRoles(CreateHouseholdCommand command) {
        if (command.roles().isEmpty()) {
            throw new InvalidHouseholdRolesException("At least one household role must be supplied.");
        }

        var roleNames = new HashSet<String>();
        var roleIds = new HashSet<UUID>();
        for (var role : command.roles()) {
            if (role.householdRoleId() == null || !roleIds.add(role.householdRoleId())) {
                throw new InvalidHouseholdRolesException("Role IDs must be provided and unique within the household.");
            }
            if (!roleNames.add(role.name())) {
                throw new InvalidHouseholdRolesException("Role names must be unique within the household.");
            }
        }

        if (command.creatorRoleId() == null || !roleIds.contains(command.creatorRoleId())) {
            throw new InvalidHouseholdRolesException("CreatorRoleId must match a supplied role ID.");
        }
    }
}
