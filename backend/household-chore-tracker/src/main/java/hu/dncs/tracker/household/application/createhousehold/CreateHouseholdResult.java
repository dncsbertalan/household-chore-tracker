package hu.dncs.tracker.household.application.createhousehold;

import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.domain.model.HouseholdRole;

import java.util.List;

public record CreateHouseholdResult(Household household, List<HouseholdRole> roles, HouseholdMember creatorMembership) {
    public CreateHouseholdResult {
        roles = List.copyOf(roles);
    }
}
