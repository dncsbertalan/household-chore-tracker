package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.HouseholdRole;
import java.util.UUID;
import java.util.Collection;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.dao.DataIntegrityViolationException;

@Repository
@RequiredArgsConstructor
@Transactional(propagation = Propagation.MANDATORY)
public class JpaHouseholdRoleRepository implements hu.dncs.tracker.household.application.repository.HouseholdRoleRepository {
    private final HouseholdRoleRepository repository;

    @Override
    public boolean anyExistsById(Collection<UUID> ids) { return !repository.findAllById(ids).isEmpty(); }

    @Override
    public List<HouseholdRole> saveAll(List<HouseholdRole> roles) {
        try {
            return repository.saveAllAndFlush(roles);
        } catch (DataIntegrityViolationException exception) {
            throw HouseholdPersistenceExceptions.translate(exception);
        }
    }
}
