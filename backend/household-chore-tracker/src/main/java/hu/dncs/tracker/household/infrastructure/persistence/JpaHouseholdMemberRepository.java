package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.HouseholdMember;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.dao.DataIntegrityViolationException;

@Repository
@RequiredArgsConstructor
@Transactional(propagation = Propagation.MANDATORY)
public class JpaHouseholdMemberRepository implements hu.dncs.tracker.household.application.repository.HouseholdMemberRepository {
    private final HouseholdMemberRepository repository;

    @Override
    public boolean existsById(UUID id) { return repository.existsById(id); }

    @Override
    public HouseholdMember save(HouseholdMember member) {
        try {
            return repository.saveAndFlush(member);
        } catch (DataIntegrityViolationException exception) {
            throw HouseholdPersistenceExceptions.translate(exception);
        }
    }
}
