package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.JoinedHousehold;
import hu.dncs.tracker.identity.api.UserInfo;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record JoinedHouseholdResponse(
        UUID householdId,
        String name,
        String description,
        UUID createdByUserId,
        Instant createdAt,
        Instant updatedAt,
        Long version,
        List<HouseholdRoleResponse> roles,
        HouseholdMemberResponse membership
) {
    public static JoinedHouseholdResponse from(JoinedHousehold joined, Map<UUID, UserInfo> users) {
        var household = joined.household();
        return new JoinedHouseholdResponse(household.getHouseholdId(), household.getName(), household.getDescription(),
                household.getCreatedByUserId(), household.getCreatedAt(), household.getUpdatedAt(), household.getVersion(),
                joined.roles().stream().map(HouseholdRoleResponse::from).toList(),
                HouseholdMemberResponse.from(joined.membership(), users.get(joined.membership().getUserId())));
    }
}
