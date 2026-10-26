package hu.dncs.tracker.idempotency.application.usecase;

import hu.dncs.tracker.idempotency.application.exception.IdempotencyKeyConflictException;
import hu.dncs.tracker.idempotency.domain.model.StoredResponse;
import hu.dncs.tracker.idempotency.domain.model.ProcessedRequestId;
import hu.dncs.tracker.idempotency.infrastructure.persistence.ProcessedRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class ExecuteIdempotentRequestUseCase {
    private final ProcessedRequestRepository repository;
    private final TransactionTemplate transaction;

    public ExecuteIdempotentRequestUseCase(ProcessedRequestRepository repository, PlatformTransactionManager manager) {
        this.repository = repository;
        transaction = new TransactionTemplate(manager);
        transaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        transaction.setIsolationLevel(TransactionDefinition.ISOLATION_READ_COMMITTED);
    }

    public StoredResponse execute(ProcessedRequestId id, String operation, String requestHash,
                                  Execution execution) throws Exception {
        try {
            return transaction.execute(status -> {
                int claimed = repository.claim(id, operation, requestHash);
                // A separate SELECT gets a fresh READ COMMITTED snapshot after a competing commit.
                var receipt = repository.findById(id).orElseThrow();
                if (claimed == 0) {
                    if (!receipt.matches(operation, requestHash)) {
                        throw new IdempotencyKeyConflictException();
                    }
                    return receipt.replay();
                }

                StoredResponse response;
                try {
                    response = execution.execute();
                } catch (Exception exception) {
                    throw new ExecutionFailure(exception);
                }
                if (response.successful()) {
                    receipt.complete(response);
                } else {
                    status.setRollbackOnly();
                }
                return response;
            });
        } catch (ExecutionFailure failure) {
            throw (Exception) failure.getCause();
        }
    }

    @FunctionalInterface
    public interface Execution {
        StoredResponse execute() throws Exception;
    }

    private static class ExecutionFailure extends RuntimeException {
        ExecutionFailure(Exception cause) {
            super(cause);
        }
    }
}
