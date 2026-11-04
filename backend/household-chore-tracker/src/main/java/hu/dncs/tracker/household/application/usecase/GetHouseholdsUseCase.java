package hu.dncs.tracker.household.application.usecase;

import hu.dncs.tracker.household.application.model.HouseholdDetails;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class GetHouseholdsUseCase {
    private final HouseholdMemberRepository members;
    private final HouseholdRoleRepository roles;

    public List<HouseholdDetails> all(UUID userId) {
        return members.findAllByUserIdOrderByHousehold_NameAsc(userId).stream().map(this::details).toList();
    }

    public HouseholdDetails one(UUID householdId, UUID userId) {
        return details(members.findByHousehold_HouseholdIdAndUserId(householdId, userId)
                .orElseThrow(() -> new AccessDeniedException("Household membership is required.")));
    }

    private HouseholdDetails details(HouseholdMember caller) {
        var household = caller.getHousehold();
        var id = household.getHouseholdId();
        var grants = caller.getHouseholdRole().getPermissions().stream().map(Permission::getName).toList();
        boolean viewMembers = grants.contains(HouseholdPermission.HOUSEHOLD_MEMBER_VIEW.name());
        boolean viewRoles = viewMembers || grants.contains(HouseholdPermission.HOUSEHOLD_ROLE_VIEW.name())
                || grants.contains(HouseholdPermission.HOUSEHOLD_MEMBER_INVITE.name());
        return new HouseholdDetails(household,
                viewRoles ? roles.findAllByHouseholdIdOrderByCreatedAtAscHouseholdRoleIdAsc(id) : List.of(caller.getHouseholdRole()),
                viewMembers ? members.findAllByHousehold_HouseholdId(id) : List.of(caller));
    }
}
