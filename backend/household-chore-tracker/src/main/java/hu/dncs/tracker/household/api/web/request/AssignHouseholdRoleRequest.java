package hu.dncs.tracker.household.api.web.request;

import jakarta.validation.constraints.*;
import java.util.UUID;

public record AssignHouseholdRoleRequest(@NotNull UUID roleId, @NotNull @Min(0) Long memberVersion, @NotNull @Min(0) Long roleVersion) {}
