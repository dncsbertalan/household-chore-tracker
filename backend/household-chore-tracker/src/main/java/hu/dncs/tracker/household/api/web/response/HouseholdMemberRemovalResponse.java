package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.HouseholdMemberRemoval;
import hu.dncs.tracker.identity.api.UserInfo;

import java.util.Map;
import java.util.UUID;

public record HouseholdMemberRemovalResponse(UUID householdId, UUID removedMemberId, HouseholdRolesResponse management) {
    public static HouseholdMemberRemovalResponse from(HouseholdMemberRemoval result, Map<UUID, UserInfo> users) {
        return new HouseholdMemberRemovalResponse(result.householdId(), result.removedMemberId(),
                result.management() == null ? null : HouseholdRolesResponse.from(result.management(), users));
    }
}
