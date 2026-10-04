package hu.dncs.tracker.identity.application.usecase;

import hu.dncs.tracker.identity.application.TokenPair;
import hu.dncs.tracker.identity.application.TokenPairIssuer;
import hu.dncs.tracker.identity.application.command.LoginCommand;
import hu.dncs.tracker.identity.domain.model.RefreshSession;
import hu.dncs.tracker.identity.domain.model.User;
import hu.dncs.tracker.identity.infrastructure.persistence.RefreshSessionRepository;
import hu.dncs.tracker.identity.infrastructure.persistence.UserRepository;
import hu.dncs.tracker.identity.infrastructure.security.TokenProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.temporal.ChronoUnit;

@Service
@RequiredArgsConstructor
public class LoginUseCase {
    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final RefreshSessionRepository refreshSessionRepository;
    private final TokenPairIssuer tokenPairIssuer;
    private final TokenProperties tokenProperties;
    private final Clock clock;

    @Transactional
    public TokenPair execute(LoginCommand command) {
        var email = User.normalizeEmail(command.email());

        authenticationManager.authenticate(UsernamePasswordAuthenticationToken.unauthenticated(email, command.password()));

        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadCredentialsException("Invalid credentials."));

        var now = clock.instant().truncatedTo(ChronoUnit.SECONDS);

        var session = refreshSessionRepository.save(new RefreshSession(user, now.plus(tokenProperties.refreshTtl())));
        
        return tokenPairIssuer.issue(session, now);
    }
}
