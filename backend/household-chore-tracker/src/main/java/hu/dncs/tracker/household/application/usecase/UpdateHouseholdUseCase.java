package hu.dncs.tracker.household.application.usecase;

import hu.dncs.tracker.household.application.HouseholdAuthorizationService;
import hu.dncs.tracker.household.application.command.UpdateHouseholdCommand;
import hu.dncs.tracker.household.application.exception.HouseholdUpdateException;
import hu.dncs.tracker.household.application.model.HouseholdDetails;
import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Objects;
import java.util.UUID;
import static hu.dncs.tracker.household.application.exception.HouseholdUpdateException.Reason.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.HOUSEHOLD_UPDATE;

@Service
@RequiredArgsConstructor
public class UpdateHouseholdUseCase {
    private final HouseholdRepository households;
    private final HouseholdAuthorizationService authorization;
    private final GetHouseholdsUseCase getHouseholds;

    @Transactional
    public HouseholdDetails execute(UUID householdId, UpdateHouseholdCommand command, UUID userId) {
        var household = households.findForUpdate(householdId)
                .orElseThrow(() -> new HouseholdUpdateException(NOT_FOUND, "Household not found."));
        authorization.requirePermission(householdId, userId, HOUSEHOLD_UPDATE);
        if (command.version() == null || !Objects.equals(household.getVersion(), command.version())) {
            throw new HouseholdUpdateException(STALE, "This household has changed. Reload it before editing.");
        }
        var name = Household.trimmedText(command.name());
        var description = Household.trimmedText(command.description());
        if (name.isEmpty() || name.length() > 100 || description.length() > 500) {
            throw new HouseholdUpdateException(INVALID, "A name of 1–100 characters and description of at most 500 characters are required.");
        }
        household.updateDetails(name, description);
        households.flush();
        return getHouseholds.one(householdId, userId);
    }
}
