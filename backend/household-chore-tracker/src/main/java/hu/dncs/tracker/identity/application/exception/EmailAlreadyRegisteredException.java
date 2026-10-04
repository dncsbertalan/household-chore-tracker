package hu.dncs.tracker.identity.application.exception;

public class EmailAlreadyRegisteredException extends RuntimeException {
    public EmailAlreadyRegisteredException() {
        super("An account with this email already exists.");
    }
}
