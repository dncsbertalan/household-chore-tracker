package hu.dncs.tracker.chore.api.web;

import hu.dncs.tracker.chore.application.exception.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

@RestControllerAdvice(assignableTypes = ChoreController.class)
class ChoreExceptionHandler extends ResponseEntityExceptionHandler {
    @ExceptionHandler(ChoreDeletionException.class)
    ProblemDetail deletion(ChoreDeletionException exception) {
        var status = exception.reason() == ChoreDeletionException.Reason.STALE ? HttpStatus.CONFLICT : HttpStatus.BAD_REQUEST;
        var problem = ProblemDetail.forStatusAndDetail(status, exception.getMessage());
        problem.setProperty("code", "chore_delete_" + exception.reason().name().toLowerCase(java.util.Locale.ROOT));
        return problem;
    }

    @ExceptionHandler(ChoreNotFoundException.class)
    ProblemDetail notFound(ChoreNotFoundException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, exception.getMessage());
    }

    @ExceptionHandler(InvalidChoreException.class)
    ProblemDetail invalid(InvalidChoreException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, exception.getMessage());
    }

    @ExceptionHandler({ChoreUpdateConflictException.class, org.springframework.orm.ObjectOptimisticLockingFailureException.class})
    ProblemDetail updateConflict(Exception exception) {
        var detail = exception instanceof ChoreUpdateConflictException ? exception.getMessage()
                : "This chore has changed. Reload it before editing.";
        var problem = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, detail);
        problem.setProperty("code", "chore_edit_conflict");
        return problem;
    }

    @ExceptionHandler(ChoreCreationConflictException.class)
    ProblemDetail conflict(ChoreCreationConflictException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT, exception.getMessage());
    }
}
