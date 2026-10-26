package hu.dncs.tracker.idempotency.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "processed_request")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ProcessedRequest {
    @EmbeddedId
    private ProcessedRequestId id;

    @Column(nullable = false, length = 100)
    private String operation;

    @Column(name = "request_hash", nullable = false, length = 64)
    private String requestHash;

    @Column(name = "response_status")
    private Integer responseStatus;

    @Column(name = "response_content_type")
    private String responseContentType;

    @Column(name = "response_location")
    private String responseLocation;

    @Column(name = "response_etag")
    private String responseEtag;

    @Column(name = "response_body")
    private byte[] responseBody;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    public boolean matches(String requestedOperation, String requestedHash) {
        return operation.equals(requestedOperation) && requestHash.equals(requestedHash);
    }

    public StoredResponse replay() {
        if (responseStatus == null) {
            throw new IllegalStateException("An incomplete idempotency receipt was committed.");
        }
        return new StoredResponse(responseStatus, responseContentType, responseLocation, responseEtag, responseBody);
    }

    public void complete(StoredResponse response) {
        if (responseStatus != null || !response.successful()) {
            throw new IllegalStateException("Only a new successful response can complete a receipt.");
        }
        responseStatus = response.status();
        responseContentType = response.contentType();
        responseLocation = response.location();
        responseEtag = response.etag();
        responseBody = response.body();
    }
}
