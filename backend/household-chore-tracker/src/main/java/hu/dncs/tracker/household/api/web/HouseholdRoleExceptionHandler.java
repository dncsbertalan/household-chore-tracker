package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.exception.HouseholdRoleManagementException;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import java.util.Locale;

@RestControllerAdvice(assignableTypes = HouseholdRoleController.class)
class HouseholdRoleExceptionHandler extends ResponseEntityExceptionHandler {
    @ExceptionHandler(HouseholdRoleManagementException.class)
    ProblemDetail failure(HouseholdRoleManagementException exception) {
        var status = switch (exception.reason()) {
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case INVALID -> HttpStatus.BAD_REQUEST;
            default -> HttpStatus.CONFLICT;
        };
        var problem = ProblemDetail.forStatusAndDetail(status, exception.getMessage());
        problem.setProperty("code", "household_role_" + exception.reason().name().toLowerCase(Locale.ROOT));
        return problem;
    }
    @ExceptionHandler(org.springframework.orm.ObjectOptimisticLockingFailureException.class)
    ProblemDetail stale(Exception exception) {
        var problem = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, "This role or membership has changed. Reload before saving.");
        problem.setProperty("code", "household_role_stale");
        return problem;
    }
}
