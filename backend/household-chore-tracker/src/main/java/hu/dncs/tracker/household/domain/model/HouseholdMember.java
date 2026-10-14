package hu.dncs.tracker.household.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;
import java.util.Objects;

@Entity
@Table(name = "household_member", uniqueConstraints =
@UniqueConstraint(columnNames = {"household_id", "user_id"})
)
@Getter
public class HouseholdMember {
    @Id
    @Column(name = "household_member_id")
    private UUID householdMemberId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "household_id", nullable = false)
    private Household household;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "nickname", length = 100)
    private String nickname;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "household_role_id", nullable = false)
    private HouseholdRole householdRole;

    @Column(name = "joined_at", nullable = false)
    private Instant joinedAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Version
    private Long version;

    protected HouseholdMember() {
    }

    public HouseholdMember(UUID householdMemberId, Household household, UUID userId, HouseholdRole householdRole) {
        this.householdMemberId = Objects.requireNonNull(householdMemberId);
        this.household = Objects.requireNonNull(household);
        this.userId = Objects.requireNonNull(userId);
        this.householdRole = Objects.requireNonNull(householdRole);

        if (!household.getHouseholdId().equals(householdRole.getHouseholdId())) {
            throw new IllegalArgumentException("Member role must belong to the same household");
        }

        this.joinedAt = Instant.now();
    }
}
