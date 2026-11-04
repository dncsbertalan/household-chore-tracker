package hu.dncs.tracker.chore.infrastructure.persistence;

import org.springframework.data.jpa.repository.EntityGraph;
import java.util.List;
import java.util.Collection;

import hu.dncs.tracker.chore.domain.model.ChoreOccurrence;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ChoreOccurrenceRepository extends JpaRepository<ChoreOccurrence, UUID> {
    @EntityGraph(attributePaths = "assignedMemberIds")
    List<ChoreOccurrence> findAllByChoreIdIn(Collection<UUID> choreIds);
}
