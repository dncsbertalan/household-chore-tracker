package hu.dncs.tracker.identity.application;

import hu.dncs.tracker.identity.domain.model.RefreshSession;
import hu.dncs.tracker.identity.domain.model.RefreshToken;
import hu.dncs.tracker.identity.infrastructure.persistence.RefreshTokenRepository;
import hu.dncs.tracker.identity.infrastructure.security.RefreshTokenGenerator;
import hu.dncs.tracker.identity.infrastructure.security.TokenProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class TokenPairIssuer {
    private final JwtEncoder encoder;
    private final TokenProperties tokenProperties;
    private final RefreshTokenGenerator refreshTokenGenerator;
    private final RefreshTokenRepository refreshTokenRepository;

    // Called within the login/refresh use case's transaction.
    public TokenPair issue(RefreshSession session, Instant now) {
        var claims = JwtClaimsSet.builder()
                .issuer(tokenProperties.issuer())
                .audience(List.of(tokenProperties.audience()))
                .subject(session.getUser().getId().toString())
                .issuedAt(now)
                .notBefore(now)
                .expiresAt(now.plus(tokenProperties.accessTtl()))
                .id(UUID.randomUUID().toString())
                .claim("token_use", "access")
                .build();
        var accessToken = encoder.encode(JwtEncoderParameters.from(
                JwsHeader.with(MacAlgorithm.HS256).build(), claims)).getTokenValue();
        var refreshToken = refreshTokenGenerator.generate();
        refreshTokenRepository.save(new RefreshToken(refreshTokenGenerator.hash(refreshToken), session));
        return new TokenPair(accessToken, refreshToken, tokenProperties.accessTtl().toSeconds(),
                Duration.between(now, session.getExpiresAt()).toSeconds());
    }
}
