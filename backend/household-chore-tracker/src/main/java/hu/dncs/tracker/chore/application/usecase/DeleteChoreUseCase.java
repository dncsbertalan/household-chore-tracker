package hu.dncs.tracker.chore.application.usecase;

import hu.dncs.tracker.chore.application.ChoreWriteLock;
import hu.dncs.tracker.chore.application.exception.ChoreDeletionException;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreRepository;
import hu.dncs.tracker.household.application.HouseholdAuthorizationService;
import hu.dncs.tracker.idempotency.application.ChoreReceiptRedaction;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Objects;
import java.util.UUID;
import static hu.dncs.tracker.chore.application.exception.ChoreDeletionException.Reason.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.CHORE_DELETE;

@Service
@RequiredArgsConstructor
public class DeleteChoreUseCase {
    private final ChoreWriteLock writeLock;
    private final ChoreRepository chores;
    private final HouseholdAuthorizationService authorization;
    private final ChoreReceiptRedaction receipts;

    @Transactional
    public void execute(UUID choreId, Long version, boolean confirmed, UUID userId) {
        var chore = writeLock.chore(choreId);
        authorization.requirePermission(chore.getHouseholdId(), userId, CHORE_DELETE);
        if (!confirmed) throw new ChoreDeletionException(CONFIRMATION_REQUIRED, "Confirm deletion of the chore and all its occurrences and history.");
        if (version == null || !Objects.equals(chore.getVersion(), version)) {
            throw new ChoreDeletionException(STALE, "This chore has changed. Reload it and confirm deletion again.");
        }
        receipts.redact(choreId);
        // Database cascades remove schedules, every occurrence, completions, approvals, and assignment rows.
        chores.delete(chore);
        chores.flush();
    }
}
