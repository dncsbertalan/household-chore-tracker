package hu.dncs.tracker.household.application.command;

import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import java.util.List;

public record SaveHouseholdRoleCommand(String name, List<HouseholdPermission> permissions, Long version) {}
