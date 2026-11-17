package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.Household;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.dao.DataIntegrityViolationException;

@Repository
@RequiredArgsConstructor
@Transactional(propagation = Propagation.MANDATORY)
public class JpaHouseholdRepository implements hu.dncs.tracker.household.application.repository.HouseholdRepository {
    private final HouseholdRepository repository;

    @Override
    public boolean existsById(UUID id) { return repository.existsById(id); }

    @Override
    public Household save(Household household) {
        try {
            return repository.saveAndFlush(household);
        } catch (DataIntegrityViolationException exception) {
            throw HouseholdPersistenceExceptions.translate(exception);
        }
    }
}
