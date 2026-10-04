package hu.dncs.tracker.identity.api.web;

import hu.dncs.tracker.identity.application.exception.EmailAlreadyRegisteredException;
import hu.dncs.tracker.identity.application.exception.InvalidRefreshTokenException;
import org.springframework.security.core.AuthenticationException;
import org.jspecify.annotations.NonNull;
import org.springframework.http.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.util.Map;

@RestControllerAdvice(assignableTypes = AuthController.class)
class RegistrationExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(AuthenticationException.class)
    ProblemDetail handleInvalidCredentials(AuthenticationException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED, "Invalid email or password.");
    }

    @ExceptionHandler(InvalidRefreshTokenException.class)
    ProblemDetail handleInvalidRefreshToken(InvalidRefreshTokenException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED, exception.getMessage());
    }

    @ExceptionHandler(EmailAlreadyRegisteredException.class)
    ProblemDetail handleDuplicateEmail(EmailAlreadyRegisteredException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, exception.getMessage());
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException exception, @NonNull HttpHeaders headers,
            @NonNull HttpStatusCode status, @NonNull WebRequest request) {
        var problem = ProblemDetail.forStatusAndDetail(status, "Authentication fields are invalid.");
        problem.setProperty("errors", exception.getBindingResult().getFieldErrors().stream()
                .map(error -> Map.of("field", error.getField(), "message", error.getDefaultMessage()))
                .toList());
        return handleExceptionInternal(exception, problem, headers, status, request);
    }
}
