package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.exception.HouseholdInvitationException;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

@RestControllerAdvice(assignableTypes = {HouseholdInvitationController.class, InvitationInboxController.class})
class HouseholdInvitationExceptionHandler extends ResponseEntityExceptionHandler {
    @ExceptionHandler(HouseholdInvitationException.class)
    ResponseEntity<ProblemDetail> handleInvitation(HouseholdInvitationException exception) {
        var status = switch (exception.getReason()) {
            case INVALID_REQUEST -> HttpStatus.BAD_REQUEST;
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case CONFLICT -> HttpStatus.CONFLICT;
            case EXPIRED -> HttpStatus.GONE;
        };
        var problem = ProblemDetail.forStatusAndDetail(status, exception.getMessage());
        problem.setProperty("code", "INVITATION_" + exception.getReason().name());
        return ResponseEntity.status(status).cacheControl(CacheControl.noStore()).body(problem);
    }
}
