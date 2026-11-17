package hu.dncs.tracker.household.application.repository;

import hu.dncs.tracker.household.domain.model.Permission;
import java.util.Optional;
import hu.dncs.tracker.household.domain.model.HouseholdPermission;

public interface PermissionRepository {
    Optional<Permission> findByName(HouseholdPermission permission);
}
