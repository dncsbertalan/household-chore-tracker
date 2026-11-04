package hu.dncs.tracker.chore.application.usecase;

import hu.dncs.tracker.chore.application.exception.ChoreNotFoundException;

import hu.dncs.tracker.chore.application.model.*;
import hu.dncs.tracker.chore.infrastructure.persistence.*;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GetChoreUseCase {
    private final ChoreRepository chores;
    private final ChoreScheduleRepository schedules;
    private final ChoreOccurrenceRepository occurrences;
    private final HouseholdMemberRepository members;

    public ChoreDetails execute(UUID id, UUID userId) {
        var chore = chores.findById(id).orElseThrow(() -> new ChoreNotFoundException());
        if (members.findByHousehold_HouseholdIdAndUserId(chore.getHouseholdId(), userId).isEmpty()) {
            throw new AccessDeniedException("Household membership is required.");
        }
        chore.getAssignedMemberIds().size();
        var history = occurrences.findAllByChoreIdOrderByCreatedAtDescChoreOccurrenceIdDesc(id);
        return new ChoreDetails(new CreatedChore(chore, schedules.findByChoreId(id).orElse(null),
                history.isEmpty() ? null : history.getFirst()), history);
    }
}
