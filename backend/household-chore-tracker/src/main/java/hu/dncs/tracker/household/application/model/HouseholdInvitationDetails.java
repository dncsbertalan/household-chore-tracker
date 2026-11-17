package hu.dncs.tracker.household.application.model;

import hu.dncs.tracker.household.domain.model.HouseholdInvitation;
import hu.dncs.tracker.household.domain.model.HouseholdInvitationStatus;
import hu.dncs.tracker.identity.api.UserInfo;

import java.time.Instant;
import java.util.UUID;

public record HouseholdInvitationDetails(
        UUID householdInvitationId,
        UUID householdId,
        String householdName,
        String invitedByLastName,
        String invitedByFirstName,
        HouseholdInvitationStatus status,
        Instant expiresAt,
        Instant createdAt
) {
    public static HouseholdInvitationDetails from(HouseholdInvitation invitation, UserInfo userInfo, Instant now) {
        return new HouseholdInvitationDetails(invitation.getHouseholdInvitationId(),
                invitation.getHousehold().getHouseholdId(), invitation.getHousehold().getName(),
                userInfo.lastName(), userInfo.firstName(), invitation.statusAt(now), invitation.getExpiresAt(),
                invitation.getCreatedAt());
    }
}
