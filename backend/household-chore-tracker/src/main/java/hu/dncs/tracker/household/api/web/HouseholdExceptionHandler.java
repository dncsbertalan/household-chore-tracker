package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.exception.HouseholdAlreadyExistsException;
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
