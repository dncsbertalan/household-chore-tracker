package hu.dncs.tracker.chore.application;

import hu.dncs.tracker.chore.application.model.ChoreActions;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.household.domain.model.*;
import org.springframework.stereotype.Component;
import java.util.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;

@Component
public class ChoreActionPolicy {
    public ChoreActions actions(Chore chore, ChoreSchedule schedule, ChoreOccurrence current,
                                ChoreCompletion pending, List<ChoreApproval> reviews, HouseholdMember actor, List<ChoreOccurrence> history) {
        if (actor.getRemovedAt() != null || !actor.getHouseholdRole().getHouseholdId().equals(chore.getHouseholdId())) {
            return new ChoreActions(false, false, false, false);
        }
        var grants = actor.getHouseholdRole().getPermissions().stream().map(Permission::getName).toList();
        var id = actor.getHouseholdMemberId();
        boolean complete = grants.contains(CHORE_COMPLETE.name());
        boolean canComplete = complete && current != null && current.isEditable()
                && (current.getAssignedMemberIds().isEmpty() || current.getAssignedMemberIds().contains(id));
        boolean selfAllowed = pending != null && (!pending.getCompletedByHouseholdMemberId().equals(id)
                || grants.contains(CHORE_SELF_APPROVE_COMPLETION.name()));
        boolean canReview = grants.contains(CHORE_APPROVE_COMPLETION.name()) && pending != null
                && current != null && current.getOccurrenceStatus() == ChoreOccurrenceStatus.AWAITING_APPROVAL
                && pending.getStatus() == ChoreCompletionStatus.AWAITING_APPROVAL
                && reviews.stream().noneMatch(a -> a.getChoreCompletionId().equals(pending.getChoreCompletionId())
                    && a.getReviewedByHouseholdMemberId().equals(id));
        boolean hasActive = history.stream().anyMatch(o -> o.isEditable() || o.getOccurrenceStatus() == ChoreOccurrenceStatus.AWAITING_APPROVAL);
        boolean canStart = !hasActive && complete && schedule != null && schedule.getScheduleType() == ChoreScheduleType.ON_DEMAND
                && (current == null || current.getOccurrenceStatus() == ChoreOccurrenceStatus.COMPLETED
                    || current.getOccurrenceStatus() == ChoreOccurrenceStatus.SKIPPED || current.getOccurrenceStatus() == ChoreOccurrenceStatus.CANCELLED)
                && (chore.getAssignedMemberIds().isEmpty() || chore.getAssignedMemberIds().contains(id));
        return new ChoreActions(canComplete, canReview && selfAllowed, canReview, canStart);
    }
}
