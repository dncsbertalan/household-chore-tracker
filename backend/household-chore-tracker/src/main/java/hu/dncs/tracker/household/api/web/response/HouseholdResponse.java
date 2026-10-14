package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.CreatedHousehold;

import java.time.Instant;
import java.util.UUID;
import java.util.List;

public record HouseholdResponse(
        UUID householdId,
        String name,
        String description,
        UUID createdByUserId,
        Instant createdAt,
        Instant updatedAt,
        Long version,
        List<HouseholdRoleResponse> roles,
        HouseholdMemberResponse creatorMembership
) {
    public static HouseholdResponse from(CreatedHousehold created) {
        var household = created.household();
        return new HouseholdResponse(household.getHouseholdId(), household.getName(), household.getDescription(),
                household.getCreatedByUserId(), household.getCreatedAt(), household.getUpdatedAt(), household.getVersion(),
                created.roles().stream().map(HouseholdRoleResponse::from).toList(),
                HouseholdMemberResponse.from(created.creatorMembership()));
    }
}
