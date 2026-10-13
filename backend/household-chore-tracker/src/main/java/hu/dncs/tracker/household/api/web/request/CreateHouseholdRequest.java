package hu.dncs.tracker.household.api.web.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record CreateHouseholdRequest(
        @NotNull UUID householdId,
        @NotBlank @Size(max = 100) String name,
        @Size(max = 500) String description
) {
    public CreateHouseholdRequest {
        name = name == null ? null : name.trim();
    }
}
