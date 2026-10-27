package hu.dncs.tracker.chore.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.*;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "chore_schedule")
@Getter
public class ChoreSchedule {
    @Id
    @Column(name = "chore_schedule_id")
    private UUID choreScheduleId;

    @Column(name = "chore_id", nullable = false, unique = true)
    private UUID choreId;

    @Enumerated(EnumType.STRING)
    @Column(name = "schedule_type", nullable = false, length = 30)
    private ChoreScheduleType scheduleType;

    @Enumerated(EnumType.STRING)
    @Column(name = "recurrence_unit", length = 10)
    private ChoreRecurrenceUnit recurrenceUnit;

    @Column(name = "recurrence_interval", nullable = false)
    private int recurrenceInterval;

    @Column(name = "starts_at")
    private LocalDateTime startsAt;

    // Retain the chosen offset when an autumn clock change repeats a local time.
    @Column(name = "starts_at_offset_seconds")
    private Integer startsAtOffsetSeconds;

    @Column(name = "time_zone_identifier", nullable = false, length = 100)
    private String timeZoneIdentifier;

    @Column(name = "updated_by_household_member_id", nullable = false)
    private UUID updatedByHouseholdMemberId;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "created_by_household_member_id", nullable = false, updatable = false)
    private UUID createdByHouseholdMemberId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    protected ChoreSchedule() {
    }

    public ChoreSchedule(UUID choreScheduleId, UUID choreId, ChoreScheduleType scheduleType, ChoreRecurrenceUnit recurrenceUnit,
                         int recurrenceInterval, Instant startsAt, String timeZoneIdentifier,
                         UUID createdByHouseholdMemberId) {
        this.choreScheduleId = choreScheduleId;
        this.choreId = choreId;
        this.scheduleType = scheduleType;
        this.recurrenceUnit = recurrenceUnit;
        this.recurrenceInterval = recurrenceInterval;
        this.timeZoneIdentifier = timeZoneIdentifier;

        if (startsAt != null) {
            var zonedStart = startsAt.atZone(ZoneId.of(timeZoneIdentifier));
            this.startsAt = zonedStart.toLocalDateTime();
            this.startsAtOffsetSeconds = zonedStart.getOffset().getTotalSeconds();
        }
        
        this.createdByHouseholdMemberId = Objects.requireNonNull(createdByHouseholdMemberId);
        this.updatedByHouseholdMemberId = createdByHouseholdMemberId;
    }

    /**
     * The API and initial occurrence retain the exact instant selected by the caller.
     */
    public Instant getStartsAtInstant() {
        return startsAt == null ? null : startsAt.toInstant(ZoneOffset.ofTotalSeconds(startsAtOffsetSeconds));
    }

    /**
     * Use calendar operations on this value when generating recurring occurrences.
     */
    public ZonedDateTime getZonedStartsAt() {
        return startsAt == null ? null : ZonedDateTime.ofLocal(startsAt,
                ZoneId.of(timeZoneIdentifier), ZoneOffset.ofTotalSeconds(startsAtOffsetSeconds));
    }
}
