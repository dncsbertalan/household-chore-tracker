package hu.dncs.tracker.chore.application.usecase;

import hu.dncs.tracker.chore.application.model.CreatedChore;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.chore.infrastructure.persistence.*;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GetChoresUseCase {
    private final ChoreRepository chores;
    private final ChoreScheduleRepository schedules;
    private final ChoreOccurrenceRepository occurrences;
    private final HouseholdMemberRepository members;

    public List<CreatedChore> execute(UUID userId, UUID householdId) {
        if (householdId != null && members.findByHousehold_HouseholdIdAndUserId(householdId, userId).isEmpty()) {
            throw new AccessDeniedException("Household membership is required.");
        }
        var visible = chores.findVisible(userId, householdId);
        if (visible.isEmpty()) return List.of();
        var ids = visible.stream().map(Chore::getChoreId).toList();
        var byChore = schedules.findAllByChoreIdIn(ids).stream().collect(Collectors.toMap(ChoreSchedule::getChoreId, Function.identity()));
        var latest = new HashMap<UUID, ChoreOccurrence>();
        for (var occurrence : occurrences.findAllByChoreIdIn(ids)) {
            latest.merge(occurrence.getChoreId(), occurrence, (a, b) ->
                    Comparator.comparing(ChoreOccurrence::getCreatedAt).thenComparing(ChoreOccurrence::getChoreOccurrenceId).compare(a, b) >= 0 ? a : b);
        }
        return visible.stream().map(c -> new CreatedChore(c, byChore.get(c.getChoreId()), latest.get(c.getChoreId()))).toList();
    }
}
