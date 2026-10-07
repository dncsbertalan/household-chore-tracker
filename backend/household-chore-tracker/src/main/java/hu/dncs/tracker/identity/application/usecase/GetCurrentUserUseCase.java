package hu.dncs.tracker.identity.application.usecase;

import hu.dncs.tracker.identity.application.exception.CurrentUserNotFoundException;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetCurrentUserUseCase {
    private final UserRepository users;

    @Transactional(readOnly = true)
    public User execute(UUID authenticatedUserId) {
        return users.findById(authenticatedUserId)
                .orElseThrow(CurrentUserNotFoundException::new);
    }
}
