package hu.dncs.tracker.identity.api;

import java.util.UUID;
import java.util.Optional;

public interface UserLookup {
    boolean userExists(UUID userId);

    Optional<String> findEmailByUserId(UUID userId);

    Optional<UUID> findUserIdByEmail(String normalizedEmail);
}
