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
        String email,
        String firstName,
        String lastName,
        String nickname,
        HouseholdRoleResponse householdRole,
        Instant joinedAt,
        Instant createdAt,
        Instant updatedAt,
        Long version
) {
    public static HouseholdMemberResponse from(HouseholdMember member, UserInfo userInfo) {
        Objects.requireNonNull(userInfo, "Household member user info is required");
        return new HouseholdMemberResponse(member.getHouseholdMemberId(), member.getHousehold().getHouseholdId(), member.getUserId(),
                userInfo.email(), userInfo.firstName(), userInfo.lastName(), member.getNickname(),
                HouseholdRoleResponse.from(member.getHouseholdRole()), member.getJoinedAt(),
                member.getCreatedAt(), member.getUpdatedAt(), member.getVersion());
    }
}
