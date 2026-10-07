package hu.dncs.tracker.identity.api.web;

import hu.dncs.tracker.identity.application.exception.CurrentUserNotFoundException;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = UserController.class)
class UserExceptionHandler {
    @ExceptionHandler(CurrentUserNotFoundException.class)
    ResponseEntity<ProblemDetail> handleMissingCurrentUser(CurrentUserNotFoundException exception) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .cacheControl(CacheControl.noStore())
                .body(ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED, exception.getMessage()));
    }
}
