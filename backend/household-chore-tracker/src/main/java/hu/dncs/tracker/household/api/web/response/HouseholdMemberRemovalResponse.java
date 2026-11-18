package hu.dncs.tracker.household.api.web.response;


import java.util.UUID;

public record HouseholdMemberRemovalResponse(UUID householdId, UUID removedMemberId,
                                             HouseholdRolesResponse management) {
}
