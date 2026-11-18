package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.HouseholdRoleManagement;

import java.util.List;

public record HouseholdRolesResponse(HouseholdResponse household, List<PermissionResponse> permissions,
                                     HouseholdRoleManagement.Actions actions) {
}
