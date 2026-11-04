package hu.dncs.tracker.household.application.model;

import hu.dncs.tracker.household.domain.model.*;
import java.util.List;

public record HouseholdDetails(Household household, List<HouseholdRole> roles, List<HouseholdMember> members) {}
