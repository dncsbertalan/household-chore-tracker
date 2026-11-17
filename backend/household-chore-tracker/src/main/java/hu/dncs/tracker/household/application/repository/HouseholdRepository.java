package hu.dncs.tracker.household.application.repository;

import hu.dncs.tracker.household.domain.model.Household;
import java.util.UUID;

public interface HouseholdRepository {
    boolean existsById(UUID id);
    Household save(Household household);
}
