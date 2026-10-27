package hu.dncs.tracker.chore.application.command;

import hu.dncs.tracker.chore.domain.model.ChoreCreationPattern;
import hu.dncs.tracker.chore.domain.model.ChoreRecurrenceUnit;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record CreateChoreCommand(
        UUID choreId, UUID householdId, String title, String description,
        ChoreCreationPattern pattern, ChoreRecurrenceUnit recurrenceUnit, int recurrenceInterval,
        Instant scheduledAt, Instant dueAt, String timeZoneIdentifier,
        List<UUID> assignedMemberIds, int requiredApprovalCount,
        UUID choreScheduleId, UUID choreOccurrenceId
) {}
