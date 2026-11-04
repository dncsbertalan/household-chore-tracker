package hu.dncs.tracker.chore.application.exception;

public class ChoreUpdateConflictException extends RuntimeException {
    public ChoreUpdateConflictException(String message) { super(message); }
}
