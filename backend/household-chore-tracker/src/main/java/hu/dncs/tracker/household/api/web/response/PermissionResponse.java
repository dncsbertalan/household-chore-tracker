package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.domain.model.Permission;

public record PermissionResponse(
        Long permissionId,
        String name,
        String description
) {
    public static PermissionResponse from(Permission permission) {
        return new PermissionResponse(permission.getPermissionId(), permission.getName(), permission.getDescription());
    }
}
