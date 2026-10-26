package hu.dncs.tracker.idempotency.infrastructure.persistence;

import hu.dncs.tracker.idempotency.domain.model.ProcessedRequest;
import hu.dncs.tracker.idempotency.domain.model.ProcessedRequestId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

public interface ProcessedRequestRepository extends JpaRepository<ProcessedRequest, ProcessedRequestId> {
    // PostgreSQL waits for an uncommitted competing claim. Do not replace with exists + insert.
    @Modifying
    @Transactional(propagation = Propagation.MANDATORY)
    @Query(value = """
            INSERT INTO processed_request (account_id, request_id, operation, request_hash)
            VALUES (:#{#id.accountId}, :#{#id.requestId}, :operation, :requestHash)
            ON CONFLICT (account_id, request_id) DO NOTHING
            """, nativeQuery = true)
    int claim(ProcessedRequestId id, String operation, String requestHash);
}
