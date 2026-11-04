package hu.dncs.tracker.chore.application;

import hu.dncs.tracker.chore.application.exception.InvalidChoreException;
import hu.dncs.tracker.chore.domain.model.*;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.time.*;
import java.util.*;

@Component
@RequiredArgsConstructor
public class ChoreInputValidator {
    private final HouseholdMemberRepository members;

    public void validate(UUID householdId, String title, String description, ChoreCreationPattern pattern,
                         ChoreRecurrenceUnit unit, int interval, Instant startsAt, Instant scheduledAt, Instant dueAt,
                         String zone, List<UUID> assignees, int approvalCount, boolean hasOccurrence) {
        var trimmed = ChoreConstraints.trimmedText(title);
        if (trimmed.isEmpty() || trimmed.length() > ChoreConstraints.TITLE_MAX_LENGTH
                || ChoreConstraints.trimmedText(description).length() > ChoreConstraints.DESCRIPTION_MAX_LENGTH) {
            throw new InvalidChoreException("A title of 1–100 characters and a description of at most 500 characters are required.");
        }
        try {
            if (zone == null || zone.length() > 100) throw new InvalidChoreException("A valid time zone is required.");
            ZoneId.of(zone);
        } catch (DateTimeException e) { throw new InvalidChoreException("A valid time zone is required."); }
        if (pattern == null || interval < 1) throw new InvalidChoreException("Invalid chore schedule.");
        boolean recurring = pattern == ChoreCreationPattern.FIXED || pattern == ChoreCreationPattern.AFTER_COMPLETION;
        if (recurring != (unit != null) || (pattern == ChoreCreationPattern.FIXED && startsAt == null)
                || ((pattern == ChoreCreationPattern.ONCE || pattern == ChoreCreationPattern.ON_DEMAND) && startsAt != null)
                || (!hasOccurrence && (scheduledAt != null || dueAt != null))
                || (scheduledAt != null && dueAt != null && dueAt.isBefore(scheduledAt))) {
            throw new InvalidChoreException("Invalid chore schedule or occurrence dates.");
        }
        if (assignees == null || assignees.stream().anyMatch(Objects::isNull)
                || new HashSet<>(assignees).size() != assignees.size()) {
            throw new InvalidChoreException("Assignee IDs must be unique household-member IDs.");
        }
        var ids = new HashSet<>(members.findAllByHousehold_HouseholdId(householdId).stream()
                .map(HouseholdMember::getHouseholdMemberId).toList());
        if (!ids.containsAll(assignees) || approvalCount < 0 || approvalCount > ids.size()) {
            throw new InvalidChoreException("Assignees and approval count must belong to the household.");
        }
    }
}
