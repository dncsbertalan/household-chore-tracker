package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.Permission;
import java.util.Optional;
import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Repository
@RequiredArgsConstructor
@Transactional(propagation = Propagation.MANDATORY)
public class JpaPermissionRepository implements hu.dncs.tracker.household.application.repository.PermissionRepository {
    private final PermissionRepository repository;

    @Override
    public Optional<Permission> findByName(HouseholdPermission permission) {
        return repository.findByName(permission);
    }
}
