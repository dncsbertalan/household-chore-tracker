package hu.dncs.tracker.household.application.model;

import java.util.UUID;

public record HouseholdMemberRemoval(UUID householdId, UUID removedMemberId, HouseholdRoleManagement management) {}
