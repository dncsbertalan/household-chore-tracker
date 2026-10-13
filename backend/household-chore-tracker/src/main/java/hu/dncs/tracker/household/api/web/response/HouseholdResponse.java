package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.domain.model.Household;

import java.time.Instant;
import java.util.UUID;

public record HouseholdResponse(
        UUID householdId,
        String name,
        String description,
        UUID createdByUserId,
        Instant createdAt,
        Instant updatedAt,
        Long version
) {
    public static HouseholdResponse from(Household household) {
        return new HouseholdResponse(household.getHouseholdId(), household.getName(), household.getDescription(),
                household.getCreatedByUserId(), household.getCreatedAt(), household.getUpdatedAt(), household.getVersion());
    }
}
