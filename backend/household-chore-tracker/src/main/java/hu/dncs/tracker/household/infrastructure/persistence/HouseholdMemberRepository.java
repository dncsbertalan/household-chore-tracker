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
    boolean existsByHouseholdRole_HouseholdRoleId(UUID roleId);

    @EntityGraph(attributePaths = {"household", "householdRole", "householdRole.permissions"})
    @Query("select m from HouseholdMember m where m.household.householdId = :householdId and m.removedAt is null")
    List<HouseholdMember> findAllByHousehold_HouseholdId(UUID householdId);

    @EntityGraph(attributePaths = {"household", "householdRole", "householdRole.permissions"})
    @Query("select m from HouseholdMember m where m.household.householdId = :householdId and m.userId = :userId and m.removedAt is null")
    Optional<HouseholdMember> findByHousehold_HouseholdIdAndUserId(UUID householdId, UUID userId);

    @Query("select m from HouseholdMember m where m.household.householdId = :householdId and m.userId = :userId")
    Optional<HouseholdMember> findIncludingRemoved(UUID householdId, UUID userId);

    @EntityGraph(attributePaths = {"household", "householdRole", "householdRole.permissions"})
    @Query("select m from HouseholdMember m where m.userId = :userId and m.removedAt is null order by m.household.name asc")
    List<HouseholdMember> findAllByUserIdOrderByHousehold_NameAsc(UUID userId);

    @Query("""
            select count(member) > 0
            from HouseholdMember member
            join member.householdRole role
            join role.permissions permission
            where member.household.householdId = :householdId
              and member.userId = :userId
              and member.removedAt is null
              and role.householdId = :householdId
              and permission.name = :permissionName
            """)
    boolean hasPermission(@Param("householdId") UUID householdId,
                          @Param("userId") UUID userId,
                          @Param("permissionName") String permissionName);
}
