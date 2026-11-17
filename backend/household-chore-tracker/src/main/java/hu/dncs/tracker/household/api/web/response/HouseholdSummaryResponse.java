package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.application.model.HouseholdDetails;
import hu.dncs.tracker.identity.api.UserInfo;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record HouseholdSummaryResponse(
        UUID householdId,
        String name,
        String description,
        List<HouseholdMemberResponse> members
) {
    public static HouseholdSummaryResponse from(HouseholdDetails details, Map<UUID, UserInfo> users) {
        var household = details.household();
        return new HouseholdSummaryResponse(household.getHouseholdId(), household.getName(), household.getDescription(),
                details.members().stream()
                        .map(member -> HouseholdMemberResponse.from(member, users.get(member.getUserId())))
                        .toList());
    }
}
