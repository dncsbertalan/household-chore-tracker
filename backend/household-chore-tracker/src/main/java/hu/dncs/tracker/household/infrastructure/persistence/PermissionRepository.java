package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import hu.dncs.tracker.household.domain.model.Permission;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Objects;
import java.util.Optional;

public interface PermissionRepository extends JpaRepository<Permission, Long> {

    Optional<Permission> findByName(String name);

    default Optional<Permission> findByName(HouseholdPermission permission) {
        return findByName(Objects.requireNonNull(permission).name());
    }
}
