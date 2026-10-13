package hu.dncs.tracker.household.application.usecase;

import hu.dncs.tracker.household.application.command.CreateHouseholdCommand;
import hu.dncs.tracker.household.application.exception.HouseholdAlreadyExistsException;
import hu.dncs.tracker.household.application.exception.HouseholdCreatorNotFoundException;
import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.domain.model.HouseholdRole;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRoleRepository;
import hu.dncs.tracker.identity.api.UserLookup;
import lombok.RequiredArgsConstructor;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CreateHouseholdUseCase {
    private final HouseholdRepository householdRepository;
    private final HouseholdRoleRepository householdRoleRepository;
    private final HouseholdMemberRepository householdMemberRepository;
    private final UserLookup userLookup;

    @Transactional
    public Household execute(CreateHouseholdCommand command, UUID authenticatedUserId) {
        if (!userLookup.userExists(authenticatedUserId)) {
            throw new HouseholdCreatorNotFoundException();
        }

        if (householdRepository.existsById(command.householdId())) {
            throw new HouseholdAlreadyExistsException();
        }

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

        var ownerRole = householdRoleRepository.saveAndFlush(new HouseholdRole(household.getHouseholdId(), "Owner", true));

        householdMemberRepository.saveAndFlush(new HouseholdMember(household.getHouseholdId(), authenticatedUserId, ownerRole));

        return household;
    }
}
