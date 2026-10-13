package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.HouseholdRole;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface HouseholdRoleRepository extends JpaRepository<HouseholdRole, UUID> {
}
