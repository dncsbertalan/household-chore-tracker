package hu.dncs.tracker.chore.infrastructure.persistence;

import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import jakarta.persistence.LockModeType;

import org.springframework.data.jpa.repository.EntityGraph;
import java.util.List;
import java.util.Collection;

import hu.dncs.tracker.chore.domain.model.ChoreOccurrence;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ChoreOccurrenceRepository extends JpaRepository<ChoreOccurrence, UUID> {
    @EntityGraph(attributePaths = "assignedMemberIds")
    List<ChoreOccurrence> findAllByChoreIdOrderByCreatedAtDescChoreOccurrenceIdDesc(UUID choreId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from ChoreOccurrence o where o.choreId = :choreId order by o.createdAt desc, o.choreOccurrenceId desc")
    List<ChoreOccurrence> findForUpdate(UUID choreId);

    @EntityGraph(attributePaths = "assignedMemberIds")
    List<ChoreOccurrence> findAllByChoreIdIn(Collection<UUID> choreIds);
}
