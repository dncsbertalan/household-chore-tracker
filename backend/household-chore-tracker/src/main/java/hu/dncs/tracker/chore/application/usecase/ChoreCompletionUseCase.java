package hu.dncs.tracker.chore.application.usecase;

import hu.dncs.tracker.chore.application.command.ChoreActionCommand;
import hu.dncs.tracker.chore.application.exception.*;
import hu.dncs.tracker.chore.application.model.ChoreDetails;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.chore.infrastructure.persistence.*;
import hu.dncs.tracker.household.application.HouseholdAuthorizationService;
import hu.dncs.tracker.chore.application.ChoreWriteLock;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;

@Service
@RequiredArgsConstructor
@Transactional
public class ChoreCompletionUseCase {
    private final ChoreRepository chores;
    private final ChoreScheduleRepository schedules;
    private final ChoreOccurrenceRepository occurrences;
    private final ChoreCompletionRepository completions;
    private final ChoreApprovalRepository approvals;
    private final HouseholdMemberRepository members;
    private final ChoreWriteLock writeLock;
    private final HouseholdAuthorizationService authorization;
    private final GetChoreUseCase getChore;
    private final Clock clock;

    public ChoreDetails start(UUID id, ChoreActionCommand command, UUID userId) {
        var chore = lock(id);
        authorization.requirePermission(chore.getHouseholdId(), userId, CHORE_COMPLETE);
        var actor = actor(chore, userId);
        requireAssignee(chore.getAssignedMemberIds(), actor);
        requireVersion(chore.getVersion(), command.version());
        var schedule = schedules.findByChoreId(id).orElse(null);
        var history = occurrences.findForUpdate(id);
        boolean active = history.stream().anyMatch(o -> o.isEditable() || o.getOccurrenceStatus() == ChoreOccurrenceStatus.AWAITING_APPROVAL);
        if (schedule == null || schedule.getScheduleType() != ChoreScheduleType.ON_DEMAND || active) throw conflict();
        occurrences.save(new ChoreOccurrence(UUID.randomUUID(), chore, null, null, actor.getHouseholdMemberId()));
        chore.recordActivity(actor.getHouseholdMemberId(), clock.instant().truncatedTo(java.time.temporal.ChronoUnit.MICROS));
        chores.flush();
        return getChore.execute(id, userId);
    }

    public ChoreDetails complete(UUID id, UUID occurrenceId, ChoreActionCommand command, UUID userId) {
        var chore = lock(id);
        authorization.requirePermission(chore.getHouseholdId(), userId, CHORE_COMPLETE);
        var actor = actor(chore, userId);
        var current = current(id, occurrenceId);
        requireAssignee(current.getAssignedMemberIds(), actor);
        requireVersion(chore.getVersion(), command.version());
        requireVersion(current.getVersion(), command.occurrenceVersion());
        if (!current.isEditable()) throw conflict();
        var now = clock.instant().truncatedTo(java.time.temporal.ChronoUnit.MICROS);
        var submission = completions.save(new ChoreCompletion(occurrenceId, actor.getHouseholdMemberId(), now, current.getRequiredApprovalCount()));
        current.submitCompletion(current.getRequiredApprovalCount() > 0, actor.getHouseholdMemberId());
        if (submission.getStatus() == ChoreCompletionStatus.APPROVED) createSuccessor(chore, current, now, actor);
        chore.recordActivity(actor.getHouseholdMemberId(), now);
        chores.flush();
        return getChore.execute(id, userId);
    }

    public ChoreDetails review(UUID id, UUID completionId, ChoreApprovalDecision decision, ChoreActionCommand command, UUID userId) {
        var chore = lock(id);
        authorization.requirePermission(chore.getHouseholdId(), userId, CHORE_APPROVE_COMPLETION);
        var actor = actor(chore, userId);
        var submission = completions.findById(completionId).orElseThrow(ChoreCompletionUseCase::conflict);
        var current = current(id, submission.getChoreOccurrenceId());
        if (decision == ChoreApprovalDecision.APPROVED && submission.getCompletedByHouseholdMemberId().equals(actor.getHouseholdMemberId())) {
            authorization.requirePermission(chore.getHouseholdId(), userId, CHORE_SELF_APPROVE_COMPLETION);
        }
        requireVersion(chore.getVersion(), command.version());
        requireVersion(current.getVersion(), command.occurrenceVersion());
        requireVersion(submission.getVersion(), command.completionVersion());
        if (current.getOccurrenceStatus() != ChoreOccurrenceStatus.AWAITING_APPROVAL
                || submission.getStatus() != ChoreCompletionStatus.AWAITING_APPROVAL) throw conflict();
        var reviews = approvals.findAllByChoreCompletionId(completionId);
        if (reviews.stream().anyMatch(a -> a.getReviewedByHouseholdMemberId().equals(actor.getHouseholdMemberId()))) throw conflict();
        var now = clock.instant().truncatedTo(java.time.temporal.ChronoUnit.MICROS);
        approvals.save(new ChoreApproval(completionId, actor.getHouseholdMemberId(), decision, now));
        long positive = reviews.stream().filter(a -> a.getDecision() == ChoreApprovalDecision.APPROVED).count()
                + (decision == ChoreApprovalDecision.APPROVED ? 1 : 0);
        if (decision == ChoreApprovalDecision.REJECTED) {
            submission.resolve(ChoreCompletionStatus.REJECTED, now);
            current.resolveCompletion(false, actor.getHouseholdMemberId());
        } else if (positive >= submission.getRequiredApprovalCount()) {
            submission.resolve(ChoreCompletionStatus.APPROVED, now);
            current.resolveCompletion(true, actor.getHouseholdMemberId());
            createSuccessor(chore, current, now, actor);
        }
        chore.recordActivity(actor.getHouseholdMemberId(), now);
        chores.flush();
        return getChore.execute(id, userId);
    }

    private void createSuccessor(Chore chore, ChoreOccurrence completed, Instant now, HouseholdMember actor) {
        var schedule = schedules.findByChoreId(chore.getChoreId()).orElse(null);
        if (schedule == null || schedule.getScheduleType() == ChoreScheduleType.ON_DEMAND) return;
        try {
            var next = ChoreRecurrence.nextScheduledAt(schedule, completed, now);
            occurrences.save(ChoreOccurrence.successor(chore, completed, next, ChoreRecurrence.nextDueAt(completed, next), actor.getHouseholdMemberId()));
        } catch (DateTimeException | ArithmeticException e) {
            throw new InvalidChoreException("The recurrence dates exceed the supported range.");
        }
    }

    private Chore lock(UUID id) { return writeLock.chore(id); }
    private HouseholdMember actor(Chore chore, UUID userId) {
        return members.findByHousehold_HouseholdIdAndUserId(chore.getHouseholdId(), userId)
                .orElseThrow(() -> new AccessDeniedException("Household membership is required."));
    }
    private ChoreOccurrence current(UUID id, UUID occurrenceId) {
        var history = occurrences.findForUpdate(id);
        if (history.isEmpty() || !history.getFirst().getChoreOccurrenceId().equals(occurrenceId)) throw conflict();
        return history.getFirst();
    }
    private static void requireAssignee(Set<UUID> assignees, HouseholdMember actor) {
        if (!assignees.isEmpty() && !assignees.contains(actor.getHouseholdMemberId())) {
            throw new AccessDeniedException("Only assigned members can complete this chore.");
        }
    }
    private static void requireVersion(Long actual, Long expected) { if (expected == null || !Objects.equals(actual, expected)) throw conflict(); }
    private static ChoreUpdateConflictException conflict() {
        return new ChoreUpdateConflictException("This chore action is no longer available. Reload its details.");
    }
}
