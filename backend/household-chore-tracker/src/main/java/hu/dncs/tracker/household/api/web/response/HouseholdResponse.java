package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.CreatedHousehold;
import hu.dncs.tracker.household.application.model.HouseholdDetails;
import hu.dncs.tracker.identity.api.UserInfo;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record HouseholdResponse(
        UUID householdId,
        String name,
        String description,
        UUID createdByUserId,
        Instant createdAt,
        Instant updatedAt,
        Long version,
        List<HouseholdRoleResponse> roles,
        HouseholdMemberResponse creatorMembership,
        List<HouseholdMemberResponse> members
) {
    public static HouseholdResponse from(HouseholdDetails details, Map<UUID, UserInfo> users) {
        var household = details.household();
        return new HouseholdResponse(household.getHouseholdId(), household.getName(), household.getDescription(),
                household.getCreatedByUserId(), household.getCreatedAt(), household.getUpdatedAt(), household.getVersion(),
                details.roles().stream().map(HouseholdRoleResponse::from).toList(), null,
                details.members().stream().map(member -> HouseholdMemberResponse.from(member, users.get(member.getUserId()))).toList());
    }

    public static HouseholdResponse from(CreatedHousehold created, Map<UUID, UserInfo> users) {
        var household = created.household();
        return new HouseholdResponse(household.getHouseholdId(), household.getName(), household.getDescription(),
                household.getCreatedByUserId(), household.getCreatedAt(), household.getUpdatedAt(), household.getVersion(),
                created.roles().stream().map(HouseholdRoleResponse::from).toList(),
                HouseholdMemberResponse.from(created.creatorMembership(), users.get(created.creatorMembership().getUserId())),
                List.of(HouseholdMemberResponse.from(created.creatorMembership(), users.get(created.creatorMembership().getUserId()))));
    }
}
