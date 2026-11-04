package hu.dncs.tracker.chore.infrastructure.persistence;

import java.util.Optional;

import java.util.List;
import java.util.Collection;

import hu.dncs.tracker.chore.domain.model.ChoreSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ChoreScheduleRepository extends JpaRepository<ChoreSchedule, UUID> {
    Optional<ChoreSchedule> findByChoreId(UUID choreId);

    List<ChoreSchedule> findAllByChoreIdIn(Collection<UUID> choreIds);
}
