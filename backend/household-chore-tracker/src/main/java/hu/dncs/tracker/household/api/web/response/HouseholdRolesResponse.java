package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.HouseholdRoleManagement;
import hu.dncs.tracker.identity.api.UserInfo;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record HouseholdRolesResponse(HouseholdResponse household, List<PermissionResponse> permissions,
                                      HouseholdRoleManagement.Actions actions) {
    public static HouseholdRolesResponse from(HouseholdRoleManagement result, Map<UUID, UserInfo> users) {
        return new HouseholdRolesResponse(HouseholdResponse.from(result.household(), users),
                result.permissions().stream().map(PermissionResponse::from).toList(), result.actions());
    }
}
