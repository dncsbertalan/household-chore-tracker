package hu.dncs.tracker.chore.infrastructure.persistence;

import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

import hu.dncs.tracker.chore.domain.model.Chore;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ChoreRepository extends JpaRepository<Chore, UUID> {
    @Query("select c.householdId from Chore c where c.choreId = :id")
    Optional<UUID> findHouseholdId(UUID id);

    List<Chore> findAllByHouseholdIdOrderByChoreId(UUID householdId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from Chore c where c.choreId = :id")
    Optional<Chore> findForUpdate(UUID id);

    @EntityGraph(attributePaths = "assignedMemberIds")
    @Query("""
        select c from Chore c where c.householdId in
        (select m.household.householdId from HouseholdMember m where m.userId = :userId and m.removedAt is null)
        and (:householdId is null or c.householdId = :householdId)
        order by c.createdAt desc, c.choreId
        """)
    List<Chore> findVisible(UUID userId, UUID householdId);
}
