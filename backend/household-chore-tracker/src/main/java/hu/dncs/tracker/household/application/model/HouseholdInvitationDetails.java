package hu.dncs.tracker.household.application.model;

import hu.dncs.tracker.household.domain.model.HouseholdInvitation;
import hu.dncs.tracker.household.domain.model.HouseholdInvitationStatus;

import java.time.Instant;
import java.util.UUID;

public record HouseholdInvitationDetails(
        UUID householdInvitationId,
        UUID householdId,
        String householdName,
        String email,
        UUID invitedByUserId,
        UUID householdRoleId,
        String householdRoleName,
        HouseholdInvitationStatus status,
        Instant expiresAt,
        Instant respondedAt,
        Instant createdAt,
        Instant updatedAt,
        Long version
) {
    public static HouseholdInvitationDetails from(HouseholdInvitation invitation, Instant now) {
        return new HouseholdInvitationDetails(invitation.getHouseholdInvitationId(),
                invitation.getHousehold().getHouseholdId(), invitation.getHousehold().getName(),
                invitation.getEmail(), invitation.getInvitedByUserId(),
                invitation.getHouseholdRole().getHouseholdRoleId(), invitation.getHouseholdRole().getName(),
                invitation.statusAt(now), invitation.getExpiresAt(), invitation.getRespondedAt(),
                invitation.getCreatedAt(), invitation.getUpdatedAt(), invitation.getVersion());
    }
}
