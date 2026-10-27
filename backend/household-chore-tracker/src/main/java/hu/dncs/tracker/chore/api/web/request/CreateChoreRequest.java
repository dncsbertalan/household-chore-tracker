package hu.dncs.tracker.chore.api.web.request;

import hu.dncs.tracker.chore.application.command.CreateChoreCommand;
import hu.dncs.tracker.chore.domain.model.ChoreCreationPattern;
import hu.dncs.tracker.chore.domain.model.ChoreRecurrenceUnit;
import jakarta.validation.constraints.*;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record CreateChoreRequest(
        @NotNull UUID choreId, @NotNull UUID householdId,
        @NotNull String title, String description,
        @NotNull ChoreCreationPattern pattern, ChoreRecurrenceUnit recurrenceUnit,
        @Min(1) int recurrenceInterval,
        Instant scheduledAt, Instant dueAt, @NotBlank @Size(max = 100) String timeZoneIdentifier,
        @NotNull List<@NotNull UUID> assignedMemberIds, @Min(0) int requiredApprovalCount,
        UUID choreScheduleId, UUID choreOccurrenceId
) {
    public CreateChoreCommand toCommand() {
        return new CreateChoreCommand(choreId, householdId, title, description, pattern, recurrenceUnit,
                recurrenceInterval, scheduledAt, dueAt, timeZoneIdentifier,
                assignedMemberIds, requiredApprovalCount, choreScheduleId, choreOccurrenceId);
    }
}
