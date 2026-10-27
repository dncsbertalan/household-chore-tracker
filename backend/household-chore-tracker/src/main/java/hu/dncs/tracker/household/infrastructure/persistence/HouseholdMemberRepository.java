package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.HouseholdMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HouseholdMemberRepository extends JpaRepository<HouseholdMember, UUID> {
    List<HouseholdMember> findAllByHousehold_HouseholdId(UUID householdId);

    Optional<HouseholdMember> findByHousehold_HouseholdIdAndUserId(UUID householdId, UUID userId);

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
