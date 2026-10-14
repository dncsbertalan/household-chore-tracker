package hu.dncs.tracker.household.application.exception;

public class HouseholdCreationConflictException extends RuntimeException {
    public HouseholdCreationConflictException() {
        super("A supplied role or membership ID already exists.");
    }
}
