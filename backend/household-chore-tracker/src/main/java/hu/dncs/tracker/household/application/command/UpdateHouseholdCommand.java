package hu.dncs.tracker.household.application.command;

public record UpdateHouseholdCommand(String name, String description, Long version) {}
