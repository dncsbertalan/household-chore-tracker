package hu.dncs.tracker.chore.api.web;

import hu.dncs.tracker.chore.application.exception.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

@RestControllerAdvice(assignableTypes = ChoreController.class)
class ChoreExceptionHandler extends ResponseEntityExceptionHandler {
    @ExceptionHandler(InvalidChoreException.class)
    ProblemDetail invalid(InvalidChoreException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, exception.getMessage());
    }

    @ExceptionHandler(ChoreCreationConflictException.class)
    ProblemDetail conflict(ChoreCreationConflictException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, exception.getMessage());
    }
}
