package hu.dncs.tracker.chore.infrastructure.persistence;

import hu.dncs.tracker.chore.domain.model.Chore;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ChoreRepository extends JpaRepository<Chore, UUID> {
}
