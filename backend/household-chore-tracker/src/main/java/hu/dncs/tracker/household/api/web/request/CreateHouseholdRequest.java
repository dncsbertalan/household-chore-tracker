package hu.dncs.tracker.household.api.web.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;
import java.util.List;

public record CreateHouseholdRequest(
        @NotNull UUID householdId,
        @NotBlank @Size(max = 100) String name,
        @Size(max = 500) String description,
        @NotEmpty List<@NotNull @Valid CreateHouseholdRoleRequest> roles,
        @NotNull UUID creatorRoleId,
        @NotNull UUID householdMemberId
) {
    public CreateHouseholdRequest {
        name = name == null ? null : name.trim();
    }
}
