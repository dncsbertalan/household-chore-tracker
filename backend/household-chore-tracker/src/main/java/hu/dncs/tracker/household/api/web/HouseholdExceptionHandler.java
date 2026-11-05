package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.exception.HouseholdAlreadyExistsException;
import hu.dncs.tracker.household.application.exception.HouseholdDeletionException;
import hu.dncs.tracker.household.application.exception.HouseholdUpdateException;
import hu.dncs.tracker.household.application.exception.HouseholdCreationConflictException;
import hu.dncs.tracker.household.application.exception.HouseholdCreatorNotFoundException;
import hu.dncs.tracker.household.application.exception.InvalidHouseholdRolesException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

@RestControllerAdvice(assignableTypes = HouseholdController.class)
class HouseholdExceptionHandler extends ResponseEntityExceptionHandler {
    @ExceptionHandler(HouseholdUpdateException.class)
    ProblemDetail handleUpdate(HouseholdUpdateException exception) {
        var status = switch (exception.reason()) {
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case INVALID -> HttpStatus.BAD_REQUEST;
            case STALE -> HttpStatus.CONFLICT;
        };
        var problem = ProblemDetail.forStatusAndDetail(status, exception.getMessage());
        problem.setProperty("code", "household_edit_" + exception.reason().name().toLowerCase(java.util.Locale.ROOT));
        return problem;
    }

    @ExceptionHandler(HouseholdDeletionException.class)
    ProblemDetail handleDeletion(HouseholdDeletionException exception) {
        var status = switch (exception.reason()) {
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case STALE -> HttpStatus.CONFLICT;
            case CONFIRMATION_REQUIRED -> HttpStatus.BAD_REQUEST;
        };
        var problem = ProblemDetail.forStatusAndDetail(status, exception.getMessage());
        problem.setProperty("code", "household_delete_" + exception.reason().name().toLowerCase(java.util.Locale.ROOT));
        return problem;
    }

    @ExceptionHandler(HouseholdCreationConflictException.class)
    ProblemDetail handleCreationConflict(HouseholdCreationConflictException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, exception.getMessage());
    }

    @ExceptionHandler(InvalidHouseholdRolesException.class)
    ProblemDetail handleInvalidRoles(InvalidHouseholdRolesException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, exception.getMessage());
    }

    @ExceptionHandler(HouseholdAlreadyExistsException.class)
    ProblemDetail handleDuplicate(HouseholdAlreadyExistsException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, exception.getMessage());
    }

    @ExceptionHandler(HouseholdCreatorNotFoundException.class)
    ProblemDetail handleMissingUser(HouseholdCreatorNotFoundException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED, exception.getMessage());
    }
}
