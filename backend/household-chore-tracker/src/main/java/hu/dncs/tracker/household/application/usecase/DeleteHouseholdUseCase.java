package hu.dncs.tracker.household.application.usecase;

import hu.dncs.tracker.household.application.HouseholdAuthorizationService;
import hu.dncs.tracker.household.application.exception.HouseholdDeletionException;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdDeletionRepository;
import hu.dncs.tracker.idempotency.application.HouseholdReceiptRedaction;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Objects;
import java.util.UUID;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.HOUSEHOLD_DELETE;
import static hu.dncs.tracker.household.application.exception.HouseholdDeletionException.Reason.*;

@Service
@RequiredArgsConstructor
public class DeleteHouseholdUseCase {
    private final HouseholdRepository households;
    private final HouseholdAuthorizationService authorization;
    private final HouseholdDeletionRepository deletion;
    private final HouseholdReceiptRedaction receipts;

    @Transactional
    public void execute(UUID householdId, Long version, boolean confirmed, UUID userId) {
        var household = households.findForUpdate(householdId)
                .orElseThrow(() -> new HouseholdDeletionException(NOT_FOUND, "Household not found."));
        authorization.requirePermission(householdId, userId, HOUSEHOLD_DELETE);
        if (!confirmed) throw new HouseholdDeletionException(CONFIRMATION_REQUIRED, "Confirm deletion of the household and all of its data.");
        if (version == null || !Objects.equals(household.getVersion(), version)) {
            throw new HouseholdDeletionException(STALE, "The household has changed. Reload it and confirm deletion again.");
        }
        receipts.redact(householdId);
        deletion.deleteData(householdId);
    }
}
