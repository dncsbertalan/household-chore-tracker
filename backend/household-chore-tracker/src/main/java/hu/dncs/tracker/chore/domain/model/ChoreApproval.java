package hu.dncs.tracker.chore.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "chore_approval", uniqueConstraints = @UniqueConstraint(columnNames = {"chore_completion_id", "reviewed_by_household_member_id"}))
@Getter
public class ChoreApproval {
    @Id private UUID choreApprovalId;
    @Column(nullable = false, updatable = false) private UUID choreCompletionId;
    @Column(nullable = false, updatable = false) private UUID reviewedByHouseholdMemberId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, updatable = false, length = 20) private ChoreApprovalDecision decision;
    @Column(nullable = false, updatable = false) private Instant reviewedAt;

    protected ChoreApproval() {}
    public ChoreApproval(UUID completionId, UUID memberId, ChoreApprovalDecision decision, Instant now) {
        choreApprovalId = UUID.randomUUID();
        choreCompletionId = completionId;
        reviewedByHouseholdMemberId = memberId;
        this.decision = decision;
        reviewedAt = now;
    }
}
