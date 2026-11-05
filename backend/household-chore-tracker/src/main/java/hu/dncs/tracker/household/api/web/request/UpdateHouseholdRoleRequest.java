package hu.dncs.tracker.household.api.web.request;

import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import hu.dncs.tracker.household.application.command.SaveHouseholdRoleCommand;
import jakarta.validation.constraints.*;
import java.util.List;

public record UpdateHouseholdRoleRequest(@NotNull String name, @NotNull List<@NotNull HouseholdPermission> permissions,
                                         @NotNull @Min(0) Long version) {
    public SaveHouseholdRoleCommand toCommand() { return new SaveHouseholdRoleCommand(name, permissions, version); }
}
