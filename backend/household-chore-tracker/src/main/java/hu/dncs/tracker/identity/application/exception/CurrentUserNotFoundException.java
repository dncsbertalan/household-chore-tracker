package hu.dncs.tracker.identity.application.exception;

public class CurrentUserNotFoundException extends RuntimeException {
    public CurrentUserNotFoundException() {
        super("The authenticated account is no longer available.");
    }
}
