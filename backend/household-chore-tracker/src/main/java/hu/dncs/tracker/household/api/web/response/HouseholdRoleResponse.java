package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.domain.model.HouseholdRole;
import hu.dncs.tracker.household.domain.model.Permission;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

public record HouseholdRoleResponse(
        UUID householdRoleId,
        UUID householdId,
        String name,
        Boolean isSystemRole,
        List<PermissionResponse> permissions,
        Instant createdAt,
        Instant updatedAt,
        Long version
) {
    public static HouseholdRoleResponse from(HouseholdRole role) {
        return new HouseholdRoleResponse(role.getHouseholdRoleId(), role.getHouseholdId(), role.getName(),
                role.getIsSystemRole(), role.getPermissions().stream()
                .sorted(Comparator.comparing(Permission::getName))
                .map(PermissionResponse::from).toList(), role.getCreatedAt(), role.getUpdatedAt(), role.getVersion());
    }
}
