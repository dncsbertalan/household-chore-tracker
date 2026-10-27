package hu.dncs.tracker.chore.application.exception;

public class ChoreCreationConflictException extends RuntimeException {
    public ChoreCreationConflictException() { super("A chore, schedule, or occurrence ID is already in use."); }
}
