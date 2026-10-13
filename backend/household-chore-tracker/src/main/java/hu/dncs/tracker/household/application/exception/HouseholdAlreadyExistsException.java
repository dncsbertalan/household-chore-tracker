package hu.dncs.tracker.household.application.exception;

public class HouseholdAlreadyExistsException extends RuntimeException {
    public HouseholdAlreadyExistsException() {
        super("A household with this ID already exists.");
    }
}
