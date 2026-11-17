package hu.dncs.tracker.household.application.repository;

import hu.dncs.tracker.household.domain.model.HouseholdRole;
import java.util.UUID;
import java.util.Collection;
import java.util.List;

public interface HouseholdRoleRepository {
    boolean anyExistsById(Collection<UUID> ids);
    List<HouseholdRole> saveAll(List<HouseholdRole> roles);
}
