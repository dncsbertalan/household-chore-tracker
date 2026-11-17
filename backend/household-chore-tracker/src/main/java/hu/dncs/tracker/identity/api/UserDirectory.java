package hu.dncs.tracker.identity.api;

import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/** Read-only user directory exposed to other modules. */
public interface UserDirectory {
    Map<UUID, UserInfo> findUserInfoByIds(Collection<UUID> userIds);

    boolean userExists(UUID userId);

    Optional<String> findEmailByUserId(UUID userId);

    Optional<UUID> findUserIdByEmail(String normalizedEmail);
}
