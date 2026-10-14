package hu.dncs.tracker.household.api.web.request;

import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record CreateHouseholdRoleRequest(
        @NotNull UUID householdRoleId,
        @NotBlank @Size(max = 50) String name,
        @NotNull List<@NotNull HouseholdPermission> permissions
) {
    public CreateHouseholdRoleRequest {
        name = name == null ? null : name.trim();
    }
}
