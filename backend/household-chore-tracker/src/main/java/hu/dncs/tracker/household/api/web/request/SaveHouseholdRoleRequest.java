package hu.dncs.tracker.household.api.web.request;

import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import hu.dncs.tracker.household.application.command.SaveHouseholdRoleCommand;
import jakarta.validation.constraints.*;
import java.util.List;

public record SaveHouseholdRoleRequest(@NotNull String name, @NotNull List<@NotNull HouseholdPermission> permissions) {
    public SaveHouseholdRoleCommand toCommand(Long version) { return new SaveHouseholdRoleCommand(name, permissions, version); }
}
