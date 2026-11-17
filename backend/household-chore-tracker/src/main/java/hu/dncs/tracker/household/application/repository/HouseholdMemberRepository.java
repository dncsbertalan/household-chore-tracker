package hu.dncs.tracker.household.application.repository;

import hu.dncs.tracker.household.domain.model.HouseholdMember;
import java.util.UUID;

public interface HouseholdMemberRepository {
    boolean existsById(UUID id);
    HouseholdMember save(HouseholdMember member);
}
