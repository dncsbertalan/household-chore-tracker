package hu.dncs.tracker.household.application.exception;

import lombok.Getter;

@Getter
public class HouseholdInvitationException extends RuntimeException {
    public enum Reason { INVALID_REQUEST, NOT_FOUND, CONFLICT, EXPIRED }

    private final Reason reason;

    public HouseholdInvitationException(Reason reason, String message) {
        super(message);
        this.reason = reason;
    }
}
