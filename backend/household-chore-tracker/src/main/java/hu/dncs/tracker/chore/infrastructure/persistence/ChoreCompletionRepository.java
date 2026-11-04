package hu.dncs.tracker.chore.infrastructure.persistence;

import hu.dncs.tracker.chore.domain.model.ChoreCompletion;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;

public interface ChoreCompletionRepository extends JpaRepository<ChoreCompletion, UUID> {
    List<ChoreCompletion> findAllByChoreOccurrenceIdInOrderBySubmittedAtDescChoreCompletionIdDesc(Collection<UUID> ids);
}
