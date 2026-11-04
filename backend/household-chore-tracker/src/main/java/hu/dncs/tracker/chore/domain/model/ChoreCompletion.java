package hu.dncs.tracker.chore.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "chore_completion")
@Getter
public class ChoreCompletion {
    @Id private UUID choreCompletionId;
    @Column(nullable = false, updatable = false) private UUID choreOccurrenceId;
    @Column(nullable = false, updatable = false) private UUID completedByHouseholdMemberId;
    @Column(nullable = false, updatable = false) private Instant submittedAt;
    @Column(nullable = false, updatable = false) private int requiredApprovalCount;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30) private ChoreCompletionStatus status;
    private Instant resolvedAt;
    @Version @Column(nullable = false) private Long version;

    protected ChoreCompletion() {}

    public ChoreCompletion(UUID occurrenceId, UUID memberId, Instant now, int requiredApprovals) {
        choreCompletionId = UUID.randomUUID();
        choreOccurrenceId = occurrenceId;
        completedByHouseholdMemberId = memberId;
        submittedAt = now;
        requiredApprovalCount = requiredApprovals;
        status = requiredApprovals == 0 ? ChoreCompletionStatus.APPROVED : ChoreCompletionStatus.AWAITING_APPROVAL;
        resolvedAt = requiredApprovals == 0 ? now : null;
    }

    public void resolve(ChoreCompletionStatus status, Instant now) {
        if (this.status != ChoreCompletionStatus.AWAITING_APPROVAL || status == ChoreCompletionStatus.AWAITING_APPROVAL) {
            throw new IllegalStateException("Only pending submissions can be resolved.");
        }
        this.status = status;
        resolvedAt = now;
    }
}
