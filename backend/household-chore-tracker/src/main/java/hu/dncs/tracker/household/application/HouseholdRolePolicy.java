package hu.dncs.tracker.household.application;

import hu.dncs.tracker.household.application.model.HouseholdRoleManagement.Actions;
import hu.dncs.tracker.household.domain.model.*;
import org.springframework.stereotype.Component;
import java.util.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;

@Component
public class HouseholdRolePolicy {
    public Actions actions(HouseholdMember actor) {
        if (actor.getRemovedAt() != null || !actor.getHousehold().getHouseholdId().equals(actor.getHouseholdRole().getHouseholdId())) {
            return new Actions(false, false, false, false, false, false);
        }
        var grants = actor.getHouseholdRole().getPermissions().stream().map(Permission::getName).toList();
        boolean create = grants.contains(HOUSEHOLD_ROLE_CREATE);
        boolean update = grants.contains(HOUSEHOLD_ROLE_UPDATE);
        boolean delete = grants.contains(HOUSEHOLD_ROLE_DELETE);
        boolean assign = grants.contains(HOUSEHOLD_MEMBER_ASSIGN_ROLE);
        boolean remove = grants.contains(HOUSEHOLD_MEMBER_REMOVE);
        boolean view = create || update || delete || assign || remove || grants.contains(HOUSEHOLD_ROLE_VIEW)
                || grants.contains(HOUSEHOLD_MEMBER_VIEW) || grants.contains(HOUSEHOLD_MEMBER_INVITE);
        return new Actions(view, create, update, delete, assign, remove);
    }
}
