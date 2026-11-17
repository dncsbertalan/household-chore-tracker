package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.HouseholdInvitationDetails;
import hu.dncs.tracker.household.domain.model.HouseholdInvitationStatus;
import hu.dncs.tracker.identity.api.UserInfo;

import java.time.Instant;
import java.util.UUID;

public record HouseholdInvitationDto(
        UUID householdInvitationId,
        UUID householdId,
        String householdName,
        String invitedByLastName,
        String invitedByFirstName,
        HouseholdInvitationStatus status,
        Instant expiresAt,
        Instant createdAt
) {
    public static HouseholdInvitationDto from(HouseholdInvitationDetails invitation) {
        return new HouseholdInvitationDto(invitation.householdInvitationId(), invitation.householdId(),
                invitation.householdName(),invitation.invitedByLastName(),invitation.invitedByFirstName(),
                invitation.status(), invitation.expiresAt(), invitation.createdAt());
    }
}
