package hu.dncs.tracker.chore.api.web.response;

import hu.dncs.tracker.chore.application.model.ChoreDetails;

import hu.dncs.tracker.chore.application.model.CreatedChore;
import hu.dncs.tracker.chore.domain.model.*;
import java.time.Instant;
import java.util.*;

public record ChoreResponse(
        UUID choreId, UUID householdId, String title, String description, UUID createdByUserId,
        Instant createdAt, Long version, List<UUID> assignedMemberIds, int requiredApprovalCount,
        Schedule schedule, Occurrence occurrence,
        UUID createdByHouseholdMemberId, UUID updatedByHouseholdMemberId, Instant updatedAt,
        List<Occurrence> occurrences
) {
    public static ChoreResponse from(CreatedChore created) {
        var chore = created.chore();
        return new ChoreResponse(chore.getChoreId(), chore.getHouseholdId(), chore.getTitle(), chore.getDescription(),
                chore.getCreatedByUserId(), chore.getCreatedAt(), chore.getVersion(), sorted(chore.getAssignedMemberIds()),
                chore.getRequiredApprovalCount(), created.schedule() == null ? null : Schedule.from(created.schedule()),
                created.occurrence() == null ? null : Occurrence.from(created.occurrence()),
                chore.getCreatedByHouseholdMemberId(), chore.getUpdatedByHouseholdMemberId(), chore.getUpdatedAt(), null);
    }

    public static ChoreResponse from(ChoreDetails details) {
        var response = from(details.current());
        return new ChoreResponse(response.choreId(), response.householdId(), response.title(), response.description(),
                response.createdByUserId(), response.createdAt(), response.version(), response.assignedMemberIds(),
                response.requiredApprovalCount(), response.schedule(), response.occurrence(), response.createdByHouseholdMemberId(),
                response.updatedByHouseholdMemberId(), response.updatedAt(), details.occurrences().stream().map(Occurrence::from).toList());
    }

    private static List<UUID> sorted(Set<UUID> ids) {
        return ids.stream().sorted(Comparator.comparing(UUID::toString)).toList();
    }

    public record Schedule(UUID choreScheduleId, ChoreScheduleType scheduleType, ChoreRecurrenceUnit recurrenceUnit,
                           int recurrenceInterval, Instant startsAt, String timeZoneIdentifier, Long version,
                           UUID createdByHouseholdMemberId, UUID updatedByHouseholdMemberId,
                           Instant createdAt, Instant updatedAt) {
        static Schedule from(ChoreSchedule schedule) {
            return new Schedule(schedule.getChoreScheduleId(), schedule.getScheduleType(), schedule.getRecurrenceUnit(),
                    schedule.getRecurrenceInterval(), schedule.getStartsAtInstant(), schedule.getTimeZoneIdentifier(), schedule.getVersion(),
                    schedule.getCreatedByHouseholdMemberId(), schedule.getUpdatedByHouseholdMemberId(),
                    schedule.getCreatedAt(), schedule.getUpdatedAt());
        }
    }

    public record Occurrence(UUID choreOccurrenceId, String title, String description, List<UUID> assignedMemberIds,
                             int requiredApprovalCount, Instant createdAt, Instant scheduledAt, Instant dueAt,
                             ChoreOccurrenceStatus occurrenceStatus, Long version,
                             UUID createdByHouseholdMemberId, UUID updatedByHouseholdMemberId, Instant updatedAt) {
        static Occurrence from(ChoreOccurrence occurrence) {
            return new Occurrence(occurrence.getChoreOccurrenceId(), occurrence.getTitle(), occurrence.getDescription(),
                    sorted(occurrence.getAssignedMemberIds()), occurrence.getRequiredApprovalCount(), occurrence.getCreatedAt(),
                    occurrence.getScheduledAt(), occurrence.getDueAt(), occurrence.getOccurrenceStatus(), occurrence.getVersion(),
                    occurrence.getCreatedByHouseholdMemberId(), occurrence.getUpdatedByHouseholdMemberId(), occurrence.getUpdatedAt());
        }
    }
}
