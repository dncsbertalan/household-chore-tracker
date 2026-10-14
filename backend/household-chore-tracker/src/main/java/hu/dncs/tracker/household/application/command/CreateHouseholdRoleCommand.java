package hu.dncs.tracker.household.application.command;

import hu.dncs.tracker.household.domain.model.HouseholdPermission;

import java.util.List;
import java.util.UUID;

public record CreateHouseholdRoleCommand(UUID householdRoleId, String name, List<HouseholdPermission> permissions) {
    public CreateHouseholdRoleCommand {
        permissions = List.copyOf(permissions);
    }
}
