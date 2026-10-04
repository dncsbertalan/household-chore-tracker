package hu.dncs.tracker.identity.application.usecase;

import hu.dncs.tracker.identity.application.TokenPair;
import hu.dncs.tracker.identity.application.TokenPairIssuer;
import hu.dncs.tracker.identity.application.exception.InvalidRefreshTokenException;
import hu.dncs.tracker.identity.infrastructure.persistence.RefreshSessionRepository;
import hu.dncs.tracker.identity.infrastructure.persistence.RefreshTokenRepository;
import hu.dncs.tracker.identity.infrastructure.security.RefreshTokenGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.temporal.ChronoUnit;

@Service
@RequiredArgsConstructor
public class RefreshTokensUseCase {
    private final RefreshTokenRepository refreshTokenRepository;
    private final RefreshSessionRepository refreshSessionRepository;
    private final RefreshTokenGenerator refreshTokenGenerator;
    private final TokenPairIssuer tokenPairIssuer;
    private final Clock clock;

    // Replay revocation must commit even though the HTTP response is 401.
    @Transactional(noRollbackFor = InvalidRefreshTokenException.class)
    public TokenPair execute(String refreshToken) {
        var hash = refreshTokenGenerator.hash(refreshToken);
        var sessionId = refreshTokenRepository.findSessionIdByTokenHash(hash)
                .orElseThrow(InvalidRefreshTokenException::new);
        
        // Lock the entire rotation chain before loading token state. This serializes
        // both same-token races and a replay racing with its successor's refresh.
        var session = refreshSessionRepository.findByIdForUpdate(sessionId)
                .orElseThrow(InvalidRefreshTokenException::new);
        var now = clock.instant();
        if (!session.isActiveAt(now)) {
            throw new InvalidRefreshTokenException();
        }

        var token = refreshTokenRepository.findById(hash).orElseThrow(InvalidRefreshTokenException::new);

        if (token.getUsedAt() != null) {
            session.revoke(now);
            throw new InvalidRefreshTokenException();
        }

        token.consume(now);

        return tokenPairIssuer.issue(session, now.truncatedTo(ChronoUnit.SECONDS));
    }
}
