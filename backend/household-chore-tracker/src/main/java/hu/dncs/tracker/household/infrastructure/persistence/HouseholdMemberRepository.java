package hu.dncs.tracker.household.infrastructure.persistence;

import org.springframework.data.jpa.repository.EntityGraph;

import hu.dncs.tracker.household.domain.model.HouseholdMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HouseholdMemberRepository extends JpaRepository<HouseholdMember, UUID> {
    @EntityGraph(attributePaths = {"household", "householdRole", "householdRole.permissions"})
    List<HouseholdMember> findAllByHousehold_HouseholdId(UUID householdId);

    @EntityGraph(attributePaths = {"household", "householdRole", "householdRole.permissions"})
    Optional<HouseholdMember> findByHousehold_HouseholdIdAndUserId(UUID householdId, UUID userId);

    @EntityGraph(attributePaths = {"household", "householdRole", "householdRole.permissions"})
    List<HouseholdMember> findAllByUserIdOrderByHousehold_NameAsc(UUID userId);

    @Query("""
            select count(member) > 0
            from HouseholdMember member
            join member.householdRole role
            join role.permissions permission
            where member.household.householdId = :householdId
              and member.userId = :userId
              and role.householdId = :householdId
              and permission.name = :permissionName
            """)
    boolean hasPermission(@Param("householdId") UUID householdId,
                          @Param("userId") UUID userId,
                          @Param("permissionName") String permissionName);
}
