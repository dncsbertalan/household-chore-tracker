package hu.dncs.tracker.identity.api;

import java.util.UUID;

public interface UserLookup {
    boolean userExists(UUID userId);
}
