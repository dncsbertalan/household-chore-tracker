package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.domain.model.HouseholdMember;

import java.time.Instant;
import java.util.UUID;

public record HouseholdMemberResponse(
        UUID householdMemberId,
        UUID householdId,
        UUID userId,
        String nickname,
        HouseholdRoleResponse householdRole,
        Instant joinedAt,
        Instant createdAt,
        Instant updatedAt,
        Long version
) {
    public static HouseholdMemberResponse from(HouseholdMember member) {
        return new HouseholdMemberResponse(member.getHouseholdMemberId(), member.getHousehold().getHouseholdId(), member.getUserId(),
                member.getNickname(), HouseholdRoleResponse.from(member.getHouseholdRole()), member.getJoinedAt(),
                member.getCreatedAt(), member.getUpdatedAt(), member.getVersion());
    }
}
