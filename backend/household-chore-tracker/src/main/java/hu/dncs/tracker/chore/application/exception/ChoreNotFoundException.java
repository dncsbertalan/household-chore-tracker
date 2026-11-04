package hu.dncs.tracker.chore.application.exception;

public class ChoreNotFoundException extends RuntimeException {
    public ChoreNotFoundException() { super("Chore not found."); }
}
