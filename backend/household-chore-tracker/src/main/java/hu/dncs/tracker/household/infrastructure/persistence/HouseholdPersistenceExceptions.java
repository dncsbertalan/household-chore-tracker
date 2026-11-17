package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.application.exception.HouseholdAlreadyExistsException;
import hu.dncs.tracker.household.application.exception.HouseholdCreationConflictException;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;

final class HouseholdPersistenceExceptions {
    private HouseholdPersistenceExceptions() {}

    static RuntimeException translate(DataIntegrityViolationException exception) {
        for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
            if (cause instanceof ConstraintViolationException violation) {
                var constraint = violation.getConstraintName();
                if ("pk_household".equals(constraint)) {
                    return new HouseholdAlreadyExistsException();
                }
                if ("pk_household_role".equals(constraint) || "pk_household_member".equals(constraint)) {
                    return new HouseholdCreationConflictException();
                }
            }
        }
        return exception;
    }
}
