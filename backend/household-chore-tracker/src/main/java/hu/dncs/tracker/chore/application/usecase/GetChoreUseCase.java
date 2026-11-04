package hu.dncs.tracker.chore.application.usecase;

import hu.dncs.tracker.chore.application.ChoreActionPolicy;
import hu.dncs.tracker.chore.domain.model.ChoreCompletion;
import hu.dncs.tracker.chore.domain.model.ChoreApproval;
import hu.dncs.tracker.chore.domain.model.ChoreOccurrence;
import hu.dncs.tracker.chore.domain.model.ChoreCompletionStatus;
import java.util.List;

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
    private final ChoreCompletionRepository completions;
    private final ChoreApprovalRepository approvals;
    private final ChoreActionPolicy policy;

    public ChoreDetails execute(UUID id, UUID userId) {
        var chore = chores.findById(id).orElseThrow(() -> new ChoreNotFoundException());
        var actor = members.findByHousehold_HouseholdIdAndUserId(chore.getHouseholdId(), userId)
                .orElseThrow(() -> new AccessDeniedException("Household membership is required."));
        chore.getAssignedMemberIds().size();
        var history = occurrences.findAllByChoreIdOrderByCreatedAtDescChoreOccurrenceIdDesc(id);
        var schedule = schedules.findByChoreId(id).orElse(null);
        var current = history.isEmpty() ? null : history.getFirst();
        var submissions = history.isEmpty() ? List.<ChoreCompletion>of()
                : completions.findAllByChoreOccurrenceIdInOrderBySubmittedAtDescChoreCompletionIdDesc(
                        history.stream().map(ChoreOccurrence::getChoreOccurrenceId).toList());
        var reviews = submissions.isEmpty() ? List.<ChoreApproval>of()
                : approvals.findAllByChoreCompletionIdInOrderByReviewedAtAscChoreApprovalIdAsc(
                        submissions.stream().map(ChoreCompletion::getChoreCompletionId).toList());
        var pending = submissions.stream().filter(c -> current != null && c.getChoreOccurrenceId().equals(current.getChoreOccurrenceId())
                && c.getStatus() == ChoreCompletionStatus.AWAITING_APPROVAL).findFirst().orElse(null);
        return new ChoreDetails(new CreatedChore(chore, schedule, current), history, submissions, reviews,
                policy.actions(chore, schedule, current, pending, reviews, actor, history));
    }
}
