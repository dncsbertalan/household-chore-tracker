package hu.dncs.tracker.chore.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.Objects;

@Entity
@Table(name = "chore")
@Getter
public class Chore {
    @Id
    @Column(name = "chore_id")
    private UUID choreId;

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    @Column(name = "title", nullable = false, length = 100)
    private String title;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "created_by_user_id", nullable = false)
    private UUID createdByUserId;

    @Column(name = "required_approval_count", nullable = false)
    private int requiredApprovalCount;

    @ElementCollection
    @CollectionTable(
            name = "chore_assigned_member",
            joinColumns = @JoinColumn(name = "chore_id")
    )
    @Column(name = "household_member_id", nullable = false)
    private Set<UUID> assignedMemberIds = new HashSet<>();

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

    protected Chore() {
    }

    public Chore(UUID choreId, UUID householdId, String title, String description,
                 UUID createdByUserId, UUID createdByHouseholdMemberId,
                 Collection<UUID> assignedMemberIds, int requiredApprovalCount) {
        this.choreId = choreId;
        this.householdId = householdId;
        this.title = title;
        this.description = description;
        this.createdByUserId = createdByUserId;
        this.createdByHouseholdMemberId = Objects.requireNonNull(createdByHouseholdMemberId);
        this.updatedByHouseholdMemberId = createdByHouseholdMemberId;
        this.assignedMemberIds.addAll(assignedMemberIds);
        this.requiredApprovalCount = requiredApprovalCount;
    }
}
