package hu.dncs.tracker.idempotency.api.web;

import hu.dncs.tracker.idempotency.application.exception.IdempotencyKeyConflictException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
class IdempotencyExceptionHandler {
    @ExceptionHandler(InvalidIdempotencyRequestException.class)
    ProblemDetail invalidRequest(InvalidIdempotencyRequestException exception) {
        var problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, exception.getMessage());
        problem.setProperty("code", "invalid_idempotency_request");
        return problem;
    }

    @ExceptionHandler(IdempotencyKeyConflictException.class)
    ProblemDetail conflict(IdempotencyKeyConflictException exception) {
        var problem = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, exception.getMessage());
        problem.setProperty("code", "idempotency_key_reused");
        return problem;
    }
}
