package hu.dncs.tracker.chore.infrastructure.persistence;

import hu.dncs.tracker.chore.domain.model.ChoreSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ChoreScheduleRepository extends JpaRepository<ChoreSchedule, UUID> {
}
