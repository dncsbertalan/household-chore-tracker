package hu.dncs.tracker.household.api.web.request;

import hu.dncs.tracker.household.application.command.UpdateHouseholdCommand;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record UpdateHouseholdRequest(@NotNull String name, String description, @NotNull @Min(0) Long version) {
    public UpdateHouseholdCommand toCommand() { return new UpdateHouseholdCommand(name, description, version); }
}
