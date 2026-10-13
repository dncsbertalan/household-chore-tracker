package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.Household;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface HouseholdRepository extends JpaRepository<Household, UUID> {
}
