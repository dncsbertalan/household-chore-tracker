package hu.dncs.tracker.identity.application;

import hu.dncs.tracker.identity.api.UserLookup;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.Optional;

@Service
@RequiredArgsConstructor
class UserLookupImpl implements UserLookup {
    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public boolean userExists(UUID userId) {
        return userRepository.existsById(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<String> findEmailByUserId(UUID userId) {
        return userRepository.findById(userId).map(user -> user.getEmail());
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<UUID> findUserIdByEmail(String normalizedEmail) {
        return userRepository.findByEmail(normalizedEmail).map(user -> user.getId());
    }
}
