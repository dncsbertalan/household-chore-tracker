package hu.dncs.tracker.household.application.exception;

public class HouseholdCreatorNotFoundException extends RuntimeException {
    public HouseholdCreatorNotFoundException() {
        super("The authenticated account is no longer available.");
    }
}
