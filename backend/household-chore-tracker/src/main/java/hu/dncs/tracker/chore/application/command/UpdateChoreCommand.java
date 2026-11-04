package hu.dncs.tracker.chore.application.command;

import hu.dncs.tracker.chore.domain.model.*;
import java.time.Instant;
import java.util.*;

public record UpdateChoreCommand(Long version, Long scheduleVersion, UUID occurrenceId, Long occurrenceVersion,
        String title, String description, ChoreCreationPattern pattern, ChoreRecurrenceUnit recurrenceUnit,
        int recurrenceInterval, Instant startsAt, Instant scheduledAt, Instant dueAt, String timeZoneIdentifier,
        List<UUID> assignedMemberIds, int requiredApprovalCount) {}
