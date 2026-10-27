package hu.dncs.tracker.chore.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
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
    private Instant startsAt;

    @Column(name = "time_zone_identifier", nullable = false, length = 100)
    private String timeZoneIdentifier;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    protected ChoreSchedule() {}

    public ChoreSchedule(UUID choreScheduleId, UUID choreId, ChoreScheduleType scheduleType, ChoreRecurrenceUnit recurrenceUnit,
                         int recurrenceInterval, Instant startsAt, String timeZoneIdentifier) {
        this.choreScheduleId = choreScheduleId;
        this.choreId = choreId;
        this.scheduleType = scheduleType;
        this.recurrenceUnit = recurrenceUnit;
        this.recurrenceInterval = recurrenceInterval;
        this.startsAt = startsAt;
        this.timeZoneIdentifier = timeZoneIdentifier;
    }
}
