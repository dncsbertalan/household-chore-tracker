package hu.dncs.tracker.chore.api.web.response;

import hu.dncs.tracker.chore.application.model.CreatedChore;
import hu.dncs.tracker.chore.domain.model.*;
import java.time.Instant;
import java.util.*;

public record ChoreResponse(
        UUID choreId, UUID householdId, String title, String description, UUID createdByUserId,
        Instant createdAt, Long version, List<UUID> assignedMemberIds, int requiredApprovalCount,
        Schedule schedule, Occurrence occurrence
) {
    public static ChoreResponse from(CreatedChore created) {
        var chore = created.chore();
        return new ChoreResponse(chore.getChoreId(), chore.getHouseholdId(), chore.getTitle(), chore.getDescription(),
                chore.getCreatedByUserId(), chore.getCreatedAt(), chore.getVersion(), sorted(chore.getAssignedMemberIds()),
                chore.getRequiredApprovalCount(), created.schedule() == null ? null : Schedule.from(created.schedule()),
                created.occurrence() == null ? null : Occurrence.from(created.occurrence()));
    }

    private static List<UUID> sorted(Set<UUID> ids) {
        return ids.stream().sorted(Comparator.comparing(UUID::toString)).toList();
    }

    public record Schedule(UUID choreScheduleId, ChoreScheduleType scheduleType, ChoreRecurrenceUnit recurrenceUnit,
                           int recurrenceInterval, Instant startsAt, String timeZoneIdentifier, Long version) {
        static Schedule from(ChoreSchedule schedule) {
            return new Schedule(schedule.getChoreScheduleId(), schedule.getScheduleType(), schedule.getRecurrenceUnit(),
                    schedule.getRecurrenceInterval(), schedule.getStartsAt(), schedule.getTimeZoneIdentifier(), schedule.getVersion());
        }
    }

    public record Occurrence(UUID choreOccurrenceId, String title, String description, List<UUID> assignedMemberIds,
                             int requiredApprovalCount, Instant createdAt, Instant scheduledAt, Instant dueAt,
                             ChoreOccurrenceStatus occurrenceStatus, Long version) {
        static Occurrence from(ChoreOccurrence occurrence) {
            return new Occurrence(occurrence.getChoreOccurrenceId(), occurrence.getTitle(), occurrence.getDescription(),
                    sorted(occurrence.getAssignedMemberIds()), occurrence.getRequiredApprovalCount(), occurrence.getCreatedAt(),
                    occurrence.getScheduledAt(), occurrence.getDueAt(), occurrence.getOccurrenceStatus(), occurrence.getVersion());
        }
    }
}
