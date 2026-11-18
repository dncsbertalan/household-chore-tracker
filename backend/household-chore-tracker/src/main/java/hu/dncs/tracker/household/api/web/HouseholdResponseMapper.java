package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.api.web.response.*;
import hu.dncs.tracker.household.application.createhousehold.CreateHouseholdResult;
import hu.dncs.tracker.household.application.model.HouseholdDetails;
import hu.dncs.tracker.household.application.model.HouseholdMemberRemoval;
import hu.dncs.tracker.household.application.model.HouseholdRoleManagement;
import hu.dncs.tracker.household.application.model.JoinedHousehold;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.identity.api.UserDirectory;
import hu.dncs.tracker.identity.api.UserInfo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.IntStream;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import java.util.Map;
import java.util.UUID;

@Component
@RequiredArgsConstructor
class HouseholdResponseMapper {
    private final UserDirectory users;
    private final HouseholdMemberRepository members;

    List<HouseholdResponse> from(List<HouseholdDetails> households, UUID callerId) {
        var owners = households.stream().map(h -> member(h, h.household().getOwnerUserId())).toList();
        var callers = households.stream().map(h -> member(h, callerId)).toList();
        var profiles = new ArrayList<>(households.stream().flatMap(h -> h.members().stream()).toList());
        profiles.addAll(owners);
        profiles.addAll(callers);
        var userInfo = userInfo(profiles);
        return IntStream.range(0, households.size()).mapToObj(i ->
                HouseholdResponse.from(households.get(i), userInfo,
                        HouseholdMemberResponse.from(owners.get(i), userInfo.get(owners.get(i).getUserId())),
                        HouseholdMemberResponse.from(callers.get(i), userInfo.get(callerId)))).toList();
    }

    List<HouseholdSummaryResponse> summaries(List<HouseholdDetails> households) {
        var userInfo = userInfo(households.stream().flatMap(household -> household.members().stream()).toList());
        return households.stream().map(household -> HouseholdSummaryResponse.from(household, userInfo)).toList();
    }

    HouseholdResponse from(HouseholdDetails household, UUID callerId) {
        var owner = member(household, household.household().getOwnerUserId());
        var me = member(household, callerId);
        var profiles = new ArrayList<>(household.members());
        profiles.add(owner);
        profiles.add(me);
        var userInfo = userInfo(profiles);
        return HouseholdResponse.from(household, userInfo,
                HouseholdMemberResponse.from(owner, userInfo.get(owner.getUserId())),
                HouseholdMemberResponse.from(me, userInfo.get(me.getUserId())));
    }

    private HouseholdMember member(HouseholdDetails household, UUID userId) {
        return household.members().stream().filter(member -> member.getUserId().equals(userId)).findFirst()
                .orElseGet(() -> members.findByHousehold_HouseholdIdAndUserId(household.household().getHouseholdId(), userId)
                        .or(() -> userId.equals(household.household().getOwnerUserId())
                                ? members.findIncludingRemoved(household.household().getHouseholdId(), userId)
                                : java.util.Optional.empty())
                        .orElseThrow(() -> new IllegalStateException("Household owner and caller memberships are required")));
    }

    HouseholdResponse from(CreateHouseholdResult household) {
        return HouseholdResponse.from(household, userInfo(List.of(household.creatorMembership())));
    }

    JoinedHouseholdResponse from(JoinedHousehold household) {
        return JoinedHouseholdResponse.from(household, userInfo(List.of(household.membership())));
    }

    HouseholdRolesResponse from(HouseholdRoleManagement roles, UUID callerId) {
        return new HouseholdRolesResponse(from(roles.household(), callerId),
                roles.permissions().stream().map(PermissionResponse::from).toList(), roles.actions());
    }

    HouseholdMemberRemovalResponse from(HouseholdMemberRemoval removal, UUID callerId) {
        return new HouseholdMemberRemovalResponse(removal.householdId(), removal.removedMemberId(),
                removal.management() == null ? null : from(removal.management(), callerId));
    }

    private Map<UUID, UserInfo> userInfo(List<HouseholdMember> members) {
        return users.findUserInfoByIds(members.stream().map(HouseholdMember::getUserId).distinct().toList());
    }
}
