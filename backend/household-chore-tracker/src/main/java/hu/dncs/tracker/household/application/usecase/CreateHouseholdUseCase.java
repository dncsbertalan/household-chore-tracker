package hu.dncs.tracker.household.application.usecase;

import hu.dncs.tracker.household.application.command.CreateHouseholdCommand;
import hu.dncs.tracker.household.application.exception.HouseholdAlreadyExistsException;
import hu.dncs.tracker.household.application.exception.HouseholdCreatorNotFoundException;
import hu.dncs.tracker.household.application.exception.InvalidHouseholdRolesException;
import hu.dncs.tracker.household.application.model.CreatedHousehold;
import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.domain.model.HouseholdRole;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRoleRepository;
import hu.dncs.tracker.household.infrastructure.persistence.PermissionRepository;
import hu.dncs.tracker.identity.api.UserLookup;
import lombok.RequiredArgsConstructor;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CreateHouseholdUseCase {
    private final HouseholdRepository householdRepository;
    private final HouseholdRoleRepository householdRoleRepository;
    private final HouseholdMemberRepository householdMemberRepository;
    private final PermissionRepository permissionRepository;
    private final UserLookup userLookup;

    @Transactional
    public CreatedHousehold execute(CreateHouseholdCommand command, UUID authenticatedUserId) {
        if (! userLookup.userExists(authenticatedUserId)) {
            throw new HouseholdCreatorNotFoundException();
        }

        if (householdRepository.existsById(command.householdId())) {
            throw new HouseholdAlreadyExistsException();
        }

        validateRoles(command);

        var household = new Household(command.householdId(), command.name(), command.description(), authenticatedUserId);

        try {
            // Flush the client-assigned ID before creating dependent records, including concurrent submissions.
            householdRepository.saveAndFlush(household);
        } catch (DataIntegrityViolationException exception) {
            for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
                if (cause instanceof ConstraintViolationException violation
                        && "pk_household".equals(violation.getConstraintName())) {
                    throw new HouseholdAlreadyExistsException();
                }
            }
            throw exception;
        }

        var roles = createRoles(command, household);

        var creatorRole = roles.stream()
                .filter(role -> role.getName().equals(command.creatorRoleName()))
                .findFirst()
                .orElseThrow();

        householdMemberRepository.saveAndFlush(new HouseholdMember(household.getHouseholdId(), authenticatedUserId, creatorRole));

        return new CreatedHousehold(household, roles);
    }

    private List<HouseholdRole> createRoles(CreateHouseholdCommand command, Household household) {
        var roles = new ArrayList<HouseholdRole>();
        for (var requestedRole : command.roles()) {
            var role = new HouseholdRole(household.getHouseholdId(), requestedRole.name(), false);

            for (var permissionName : requestedRole.permissions()) {
                role.getPermissions().add(permissionRepository.findByName(permissionName)
                        .orElseThrow(() -> new IllegalStateException("Missing seeded permission: " + permissionName)));
            }

            roles.add(role);
        }
        return householdRoleRepository.saveAllAndFlush(roles);
    }

    private void validateRoles(CreateHouseholdCommand command) {
        if (command.roles().isEmpty()) {
            throw new InvalidHouseholdRolesException("At least one household role must be supplied.");
        }

        var roleNames = new HashSet<String>();
        for (var role : command.roles()) {
            if (! roleNames.add(role.name())) {
                throw new InvalidHouseholdRolesException("Role names must be unique within the household.");
            }
        }

        if (command.creatorRoleName() == null || ! roleNames.contains(command.creatorRoleName())) {
            throw new InvalidHouseholdRolesException("CreatorRoleName must match a supplied role name.");
        }
    }
}
