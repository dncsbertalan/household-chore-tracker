package hu.dncs.tracker.household.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "household_member", uniqueConstraints =
@UniqueConstraint(columnNames = {"household_id", "user_id"})
)
@Getter
public class HouseholdMember {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "household_member_id")
    private UUID householdMemberId;

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

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
}
