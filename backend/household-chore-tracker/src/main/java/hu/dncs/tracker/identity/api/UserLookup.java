package hu.dncs.tracker.identity.api;


import java.util.Collection;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public interface UserLookup {
    Map<UUID, UserInfo> findUserInfoByIds(Collection<UUID> userIds);

    boolean userExists(UUID userId);

    Optional<String> findEmailByUserId(UUID userId);

    Optional<UUID> findUserIdByEmail(String normalizedEmail);
}
