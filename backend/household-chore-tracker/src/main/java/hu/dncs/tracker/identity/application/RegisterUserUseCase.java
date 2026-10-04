package hu.dncs.tracker.identity.application;

import hu.dncs.tracker.identity.application.exception.EmailAlreadyRegisteredException;
import hu.dncs.tracker.identity.domain.model.PasswordCredential;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.PasswordCredentialRepository;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import lombok.RequiredArgsConstructor;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RegisterUserUseCase {

    private final UserRepository userRepository;
    private final PasswordCredentialRepository passwordCredentialRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public User execute(RegisterUserCommand command) {
        var email = User.normalizeEmail(command.email());
        if (userRepository.existsByEmail(email)) {
            throw new EmailAlreadyRegisteredException();
        }

        var user = new User(email, command.firtName(), command.lastName());
        var passwordHash = passwordEncoder.encode(command.password());
        try {
            userRepository.saveAndFlush(user);
            passwordCredentialRepository.saveAndFlush(new PasswordCredential(user, passwordHash));
            return user;
        } catch (DataIntegrityViolationException exception) {
            // The unique constraint also protects concurrent registrations that both pass the lookup.
            for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
                if (cause instanceof ConstraintViolationException violation
                        && "uc_users_email".equals(violation.getConstraintName())) {
                    throw new EmailAlreadyRegisteredException();
                }
            }
            throw exception;
        }
    }
}
