package hu.dncs.tracker.chore.application.exception;

public class ChoreDeletionException extends RuntimeException {
    public enum Reason { STALE, CONFIRMATION_REQUIRED }
    private final Reason reason;
    public ChoreDeletionException(Reason reason, String message) { super(message); this.reason = reason; }
    public Reason reason() { return reason; }
}
