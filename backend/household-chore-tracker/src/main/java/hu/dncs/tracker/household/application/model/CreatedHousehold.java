package hu.dncs.tracker.household.application.model;

import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.domain.model.HouseholdRole;

import java.util.List;

public record CreatedHousehold(Household household, List<HouseholdRole> roles, HouseholdMember creatorMembership) {
    public CreatedHousehold {
        roles = List.copyOf(roles);
    }
}
