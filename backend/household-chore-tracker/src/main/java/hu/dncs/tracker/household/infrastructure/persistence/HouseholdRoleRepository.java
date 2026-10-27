package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.HouseholdRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import java.util.List;
import java.util.UUID;

public interface HouseholdRoleRepository extends JpaRepository<HouseholdRole, UUID> {
    @EntityGraph(attributePaths = "permissions")
    List<HouseholdRole> findAllByHouseholdIdOrderByCreatedAtAscHouseholdRoleIdAsc(UUID householdId);
}
