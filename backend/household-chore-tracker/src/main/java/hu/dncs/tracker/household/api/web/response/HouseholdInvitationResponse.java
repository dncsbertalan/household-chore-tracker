package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.HouseholdInvitationDetails;
import hu.dncs.tracker.household.domain.model.HouseholdInvitationStatus;

import java.time.Instant;
import java.util.UUID;

public record HouseholdInvitationResponse(
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
    public static HouseholdInvitationResponse from(HouseholdInvitationDetails invitation) {
        return new HouseholdInvitationResponse(invitation.householdInvitationId(), invitation.householdId(),
                invitation.householdName(), invitation.email(), invitation.invitedByUserId(),
                invitation.householdRoleId(), invitation.householdRoleName(), invitation.status(),
                invitation.expiresAt(), invitation.respondedAt(), invitation.createdAt(),
                invitation.updatedAt(), invitation.version());
    }
}
