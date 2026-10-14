package hu.dncs.tracker.household.application.command;

import java.util.List;
import java.util.UUID;

public record CreateHouseholdCommand(
        UUID householdId,
        String name,
        String description,
        List<CreateHouseholdRoleCommand> roles,
        String creatorRoleName
) {
    public CreateHouseholdCommand {
        roles = roles == null ? List.of() : List.copyOf(roles);
    }
}
