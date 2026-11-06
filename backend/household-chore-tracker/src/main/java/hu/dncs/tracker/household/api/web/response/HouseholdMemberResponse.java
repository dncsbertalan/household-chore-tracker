package hu.dncs.tracker.household.api.web.response;

import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.identity.api.UserInfo;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public record HouseholdMemberResponse(
        UUID householdMemberId,
        UUID householdId,
        UUID userId,
        UserInfo userInfo,
        String nickname,
        HouseholdRoleResponse householdRole,
        Instant joinedAt,
        Instant createdAt,
        Instant updatedAt,
        Long version
) {
    public static HouseholdMemberResponse from(HouseholdMember member, UserInfo userInfo) {
        return new HouseholdMemberResponse(member.getHouseholdMemberId(), member.getHousehold().getHouseholdId(), member.getUserId(),
                Objects.requireNonNull(userInfo, "Household member user info is required"), member.getNickname(),
                HouseholdRoleResponse.from(member.getHouseholdRole()), member.getJoinedAt(),
                member.getCreatedAt(), member.getUpdatedAt(), member.getVersion());
    }
}
