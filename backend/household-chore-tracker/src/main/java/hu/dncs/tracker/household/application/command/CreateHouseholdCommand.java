package hu.dncs.tracker.household.application.command;

import java.util.UUID;

public record CreateHouseholdCommand(UUID householdId, String name, String description) {}
