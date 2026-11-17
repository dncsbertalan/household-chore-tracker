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

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
@RequiredArgsConstructor
class HouseholdResponseMapper {
    private final UserDirectory users;

    List<HouseholdResponse> from(List<HouseholdDetails> households) {
        var userInfo = userInfo(households.stream().flatMap(household -> household.members().stream()).toList());
        return households.stream().map(household -> HouseholdResponse.from(household, userInfo)).toList();
    }

    List<HouseholdSummaryResponse> summaries(List<HouseholdDetails> households) {
        var userInfo = userInfo(households.stream().flatMap(household -> household.members().stream()).toList());
        return households.stream().map(household -> HouseholdSummaryResponse.from(household, userInfo)).toList();
    }

    HouseholdResponse from(HouseholdDetails household) {
        return HouseholdResponse.from(household, userInfo(household.members()));
    }

    HouseholdResponse from(CreateHouseholdResult household) {
        return HouseholdResponse.from(household, userInfo(List.of(household.creatorMembership())));
    }

    JoinedHouseholdResponse from(JoinedHousehold household) {
        return JoinedHouseholdResponse.from(household, userInfo(List.of(household.membership())));
    }

    HouseholdRolesResponse from(HouseholdRoleManagement roles) {
        return HouseholdRolesResponse.from(roles, userInfo(roles.household().members()));
    }

    HouseholdMemberRemovalResponse from(HouseholdMemberRemoval removal) {
        return HouseholdMemberRemovalResponse.from(removal,
                removal.management() == null ? Map.of() : userInfo(removal.management().household().members()));
    }

    private Map<UUID, UserInfo> userInfo(List<HouseholdMember> members) {
        return users.findUserInfoByIds(members.stream().map(HouseholdMember::getUserId).distinct().toList());
    }
}
