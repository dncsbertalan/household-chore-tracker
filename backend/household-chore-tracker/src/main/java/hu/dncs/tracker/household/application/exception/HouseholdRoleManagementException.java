package hu.dncs.tracker.household.application.exception;

public class HouseholdRoleManagementException extends RuntimeException {
    public enum Reason { NOT_FOUND, INVALID, STALE, DUPLICATE_NAME, SYSTEM_ROLE, IN_USE, LAST_MANAGER }
    private final Reason reason;
    public HouseholdRoleManagementException(Reason reason, String message) { super(message); this.reason = reason; }
    public Reason reason() { return reason; }
}
