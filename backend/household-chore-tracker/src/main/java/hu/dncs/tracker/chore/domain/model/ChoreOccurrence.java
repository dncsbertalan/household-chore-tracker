package hu.dncs.tracker.chore.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.*;

@Entity
@Table(name = "chore_occurrence")
@Getter
public class ChoreOccurrence {
    @Id
    @Column(name = "chore_occurrence_id")
    private UUID choreOccurrenceId;

    @Column(name = "chore_id", nullable = false)
    private UUID choreId;

    @Column(name = "title", nullable = false, length = 100)
    private String title;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "required_approval_count", nullable = false)
    private int requiredApprovalCount;

    @ElementCollection
    @CollectionTable(name = "chore_occurrence_assigned_member", joinColumns = @JoinColumn(name = "chore_occurrence_id"))
    @Column(name = "household_member_id", nullable = false)
    private Set<UUID> assignedMemberIds = new HashSet<>();

    @Column(name = "scheduled_at")
    private Instant scheduledAt;

    @Column(name = "due_at")
    private Instant dueAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "occurrence_status", nullable = false, length = 30)
    private ChoreOccurrenceStatus occurrenceStatus;

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

    protected ChoreOccurrence() {}

    public ChoreOccurrence(UUID choreOccurrenceId, Chore chore, Instant scheduledAt, Instant dueAt,
                           UUID createdByHouseholdMemberId) {
        this.choreOccurrenceId = choreOccurrenceId;
        this.choreId = chore.getChoreId();
        this.title = chore.getTitle();
        this.description = chore.getDescription();
        this.assignedMemberIds.addAll(chore.getAssignedMemberIds());
        this.requiredApprovalCount = chore.getRequiredApprovalCount();
        this.scheduledAt = scheduledAt;
        this.dueAt = dueAt;
        this.occurrenceStatus = ChoreOccurrenceStatus.PENDING;
        this.createdByHouseholdMemberId = Objects.requireNonNull(createdByHouseholdMemberId);
        this.updatedByHouseholdMemberId = createdByHouseholdMemberId;
    }
}
