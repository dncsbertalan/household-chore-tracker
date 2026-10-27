package hu.dncs.tracker.household.domain.model;

import jakarta.persistence.*;
import lombok.Getter;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "household_invitation")
@Getter
public class HouseholdInvitation {
    @Id
    @Column(name = "household_invitation_id")
    private UUID householdInvitationId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "household_id", nullable = false)
    private Household household;

    @Column(name = "email", nullable = false)
    private String email;

    @Column(name = "invited_by_user_id", nullable = false)
    private UUID invitedByUserId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "household_role_id", nullable = false)
    private HouseholdRole householdRole;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private HouseholdInvitationStatus status;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "responded_at")
    private Instant respondedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    protected HouseholdInvitation() {
    }

    public HouseholdInvitation(UUID id, Household household, String email, UUID invitedByUserId,
                               HouseholdRole role, Instant now, Instant expiresAt) {
        this.householdInvitationId = Objects.requireNonNull(id);
        this.household = Objects.requireNonNull(household);
        this.email = Objects.requireNonNull(email);
        this.invitedByUserId = Objects.requireNonNull(invitedByUserId);
        this.householdRole = Objects.requireNonNull(role);
        this.createdAt = Objects.requireNonNull(now);
        this.updatedAt = now;
        this.expiresAt = Objects.requireNonNull(expiresAt);
        if (!household.getHouseholdId().equals(role.getHouseholdId())) {
            throw new IllegalArgumentException("Invitation role must belong to the same household.");
        }
        if (!expiresAt.isAfter(now)) {
            throw new IllegalArgumentException("Invitation expiry must be in the future.");
        }
        this.status = HouseholdInvitationStatus.PENDING;
    }

    public HouseholdInvitationStatus statusAt(Instant now) {
        return status == HouseholdInvitationStatus.PENDING && !expiresAt.isAfter(now)
                ? HouseholdInvitationStatus.EXPIRED : status;
    }

    public void respond(HouseholdInvitationStatus response, Instant now) {
        if (status != HouseholdInvitationStatus.PENDING || response == HouseholdInvitationStatus.PENDING
                || (response == HouseholdInvitationStatus.EXPIRED) != (statusAt(now) == HouseholdInvitationStatus.EXPIRED)) {
            throw new IllegalStateException("Invitation cannot transition to the requested status.");
        }
        this.status = Objects.requireNonNull(response);
        this.respondedAt = now;
        this.updatedAt = now;
    }
}
