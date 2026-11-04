package hu.dncs.tracker.chore.api.web.request;

import hu.dncs.tracker.chore.application.command.UpdateChoreCommand;
import hu.dncs.tracker.chore.domain.model.ChoreCreationPattern;
import hu.dncs.tracker.chore.domain.model.ChoreRecurrenceUnit;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record UpdateChoreRequest(
        @NotNull @Min(0) Long version,
        @Min(0) Long scheduleVersion,
        UUID occurrenceId,
        @Min(0) Long occurrenceVersion,
        @NotNull String title,
        String description,
        @NotNull ChoreCreationPattern pattern,
        ChoreRecurrenceUnit recurrenceUnit,
        @Min(1) int recurrenceInterval,
        Instant startsAt,
        Instant scheduledAt,
        Instant dueAt,
        @NotBlank @Size(max = 100) String timeZoneIdentifier,
        @NotNull List<@NotNull UUID> assignedMemberIds,
        @Min(0) int requiredApprovalCount
) {
    public UpdateChoreCommand toCommand() {
        return new UpdateChoreCommand(version, scheduleVersion, occurrenceId, occurrenceVersion, title, description,
                pattern, recurrenceUnit, recurrenceInterval, startsAt, scheduledAt, dueAt, timeZoneIdentifier,
                assignedMemberIds, requiredApprovalCount);
    }
}
