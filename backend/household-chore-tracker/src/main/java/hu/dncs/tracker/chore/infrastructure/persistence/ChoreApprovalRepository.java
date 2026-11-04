package hu.dncs.tracker.chore.infrastructure.persistence;

import hu.dncs.tracker.chore.domain.model.ChoreApproval;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface ChoreApprovalRepository extends JpaRepository<ChoreApproval, UUID> {
    List<ChoreApproval> findAllByChoreCompletionIdInOrderByReviewedAtAscChoreApprovalIdAsc(Collection<UUID> ids);
    List<ChoreApproval> findAllByChoreCompletionId(UUID id);
}
