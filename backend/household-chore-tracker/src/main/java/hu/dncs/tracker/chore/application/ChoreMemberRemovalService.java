package hu.dncs.tracker.chore.application;

import hu.dncs.tracker.chore.infrastructure.persistence.*;
import hu.dncs.tracker.chore.domain.model.ChoreOccurrenceStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import java.time.Clock;
import java.util.UUID;

/** Called within the membership transaction, with its household write lock already held. */
@Service
@RequiredArgsConstructor
public class ChoreMemberRemovalService {
    private final ChoreRepository chores;
    private final ChoreOccurrenceRepository occurrences;
    private final ChoreScheduleRepository schedules;
    private final Clock clock;

    @Transactional(propagation = Propagation.MANDATORY)
    public void removeAssignments(UUID householdId, UUID memberId, UUID actor) {
        var now = clock.instant();
        for (var chore : chores.findAllByHouseholdIdOrderByChoreId(householdId)) {
            var history = occurrences.findForUpdate(chore.getChoreId());
            boolean changed = false;
            for (var occurrence : history) changed |= occurrence.removeActiveAssignee(memberId, actor, now);
            boolean hasFuture = history.isEmpty() || history.stream().anyMatch(o -> o.isEditable()
                    || o.getOccurrenceStatus() == ChoreOccurrenceStatus.AWAITING_APPROVAL)
                    || schedules.findByChoreId(chore.getChoreId()).isPresent();
            if (hasFuture) changed |= chore.removeAssignee(memberId, actor, now);
            if (changed) chore.recordActivity(actor, now);
        }
        chores.flush();
    }
}
