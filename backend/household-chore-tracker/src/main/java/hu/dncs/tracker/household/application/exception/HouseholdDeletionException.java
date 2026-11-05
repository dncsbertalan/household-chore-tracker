package hu.dncs.tracker.household.application.exception;

public class HouseholdDeletionException extends RuntimeException {
    public enum Reason { NOT_FOUND, STALE, CONFIRMATION_REQUIRED }
    private final Reason reason;
    public HouseholdDeletionException(Reason reason, String message) { super(message); this.reason = reason; }
    public Reason reason() { return reason; }
}
