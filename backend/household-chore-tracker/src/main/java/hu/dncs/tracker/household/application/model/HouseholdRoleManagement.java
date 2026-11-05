package hu.dncs.tracker.household.application.model;

import hu.dncs.tracker.household.domain.model.Permission;
import java.util.List;

public record HouseholdRoleManagement(HouseholdDetails household, List<Permission> permissions, Actions actions) {
    public record Actions(boolean canView, boolean canCreate, boolean canUpdate, boolean canDelete, boolean canAssignRoles, boolean canRemoveMembers) {}
}
