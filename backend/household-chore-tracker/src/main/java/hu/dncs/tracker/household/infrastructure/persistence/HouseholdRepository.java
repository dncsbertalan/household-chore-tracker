package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.Household;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface HouseholdRepository extends JpaRepository<Household, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select household from Household household where household.householdId = :householdId")
    Optional<Household> findForUpdate(@Param("householdId") UUID householdId);
}
