package hu.dncs.tracker.household.application.command;

import hu.dncs.tracker.household.domain.model.HouseholdPermission;

import java.util.Set;
import java.util.UUID;

public record CreateHouseholdRoleCommand(UUID householdRoleId, String name, Set<HouseholdPermission> permissions) {
    public CreateHouseholdRoleCommand {
        permissions = Set.copyOf(permissions);
    }
}
