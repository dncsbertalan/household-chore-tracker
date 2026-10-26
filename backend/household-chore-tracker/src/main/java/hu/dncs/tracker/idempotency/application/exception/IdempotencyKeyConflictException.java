package hu.dncs.tracker.idempotency.application.exception;

public class IdempotencyKeyConflictException extends RuntimeException {
    public IdempotencyKeyConflictException() {
        super("This Idempotency-Key was already used for a different request.");
    }
}
