package hu.dncs.tracker.household.application;

import hu.dncs.tracker.household.domain.model.HouseholdPermission;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;
import java.util.UUID;

/**
 * Checks current membership and role grants within a household.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HouseholdAuthorizationService {
    private final HouseholdMemberRepository householdMemberRepository;

    /**
     * The user ID must come from the authenticated caller, not request payload data.
     */
    public boolean hasPermission(UUID householdId, UUID authenticatedUserId, HouseholdPermission permission) {
        return householdMemberRepository.hasPermission(Objects.requireNonNull(householdId),
                Objects.requireNonNull(authenticatedUserId), Objects.requireNonNull(permission).name());
    }

    /**
     * Call before a protected operation in its transaction. Spring Security maps a denied authenticated request to HTTP 403.
     */
    public void requirePermission(UUID householdId, UUID authenticatedUserId, HouseholdPermission permission) {
        if (!hasPermission(householdId, authenticatedUserId, permission)) {
            throw new AccessDeniedException("Missing household permission: " + permission.name());
        }
    }
}
