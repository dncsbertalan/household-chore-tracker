package hu.dncs.tracker.idempotency.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.UUID;

@Embeddable
@Getter
@EqualsAndHashCode
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ProcessedRequestId implements Serializable {
    @Column(name = "account_id", nullable = false)
    private UUID accountId;

    @Column(name = "request_id", nullable = false)
    private UUID requestId;
}
