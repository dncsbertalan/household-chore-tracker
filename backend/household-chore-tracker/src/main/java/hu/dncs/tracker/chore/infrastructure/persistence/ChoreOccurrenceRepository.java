package hu.dncs.tracker.chore.infrastructure.persistence;

import hu.dncs.tracker.chore.domain.model.ChoreOccurrence;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ChoreOccurrenceRepository extends JpaRepository<ChoreOccurrence, UUID> {
}
