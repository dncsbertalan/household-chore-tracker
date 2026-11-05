package hu.dncs.tracker.household.application.exception;

public class HouseholdUpdateException extends RuntimeException {
    public enum Reason { NOT_FOUND, INVALID, STALE }
    private final Reason reason;
    public HouseholdUpdateException(Reason reason, String message) { super(message); this.reason = reason; }
    public Reason reason() { return reason; }
}
