package hu.dncs.tracker.household.infrastructure.persistence;

import hu.dncs.tracker.household.domain.model.HouseholdInvitation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HouseholdInvitationRepository extends JpaRepository<HouseholdInvitation, UUID> {
    @Query("select invitation.household.householdId from HouseholdInvitation invitation where invitation.householdInvitationId = :id")
    Optional<UUID> findHouseholdId(@Param("id") UUID id);

    @Query("""
            select invitation from HouseholdInvitation invitation
            where invitation.household.householdId = :householdId and invitation.email = :email
              and invitation.status = hu.dncs.tracker.household.domain.model.HouseholdInvitationStatus.PENDING
            """)
    Optional<HouseholdInvitation> findPending(@Param("householdId") UUID householdId, @Param("email") String email);

    @Query("""
            select invitation from HouseholdInvitation invitation
            join fetch invitation.household join fetch invitation.householdRole
            where invitation.email = :email
              and invitation.status = hu.dncs.tracker.household.domain.model.HouseholdInvitationStatus.PENDING
              and invitation.expiresAt > :now
            order by invitation.createdAt desc, invitation.householdInvitationId
            """)
    List<HouseholdInvitation> findInbox(@Param("email") String email, @Param("now") Instant now);

    @Query("""
            select invitation from HouseholdInvitation invitation
            join fetch invitation.household join fetch invitation.householdRole
            where invitation.household.householdId = :householdId
            order by invitation.createdAt desc, invitation.householdInvitationId
            """)
    List<HouseholdInvitation> findForHousehold(@Param("householdId") UUID householdId);
}
