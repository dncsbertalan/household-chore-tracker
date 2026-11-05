package hu.dncs.tracker.household.infrastructure.persistence;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/** Deletes the entire owned graph, including archived memberships, after household authorization and locking. */
@Repository
@RequiredArgsConstructor
public class HouseholdDeletionRepository {
    private final JdbcTemplate jdbc;

    @Transactional(propagation = Propagation.MANDATORY)
    public void deleteData(UUID householdId) {
        // Chore cascades remove schedules, all occurrences, assignments, completions, and approvals first.
        jdbc.update("delete from chore where household_id = ?", householdId);
        jdbc.update("delete from household_invitation where household_id = ?", householdId);
        jdbc.update("delete from household_member where household_id = ?", householdId);
        jdbc.update("delete from household_role_permission where household_role_id in (select household_role_id from household_role where household_id = ?)", householdId);
        jdbc.update("delete from household_role where household_id = ?", householdId);
        jdbc.update("delete from household where household_id = ?", householdId);
    }
}
