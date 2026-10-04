package hu.dncs.tracker.identity.infrastructure.security;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.time.Clock;
import java.time.Duration;
import java.util.Base64;
import java.util.UUID;

@Configuration(proxyBeanMethods = false)
@EnableConfigurationProperties(TokenProperties.class)
public class TokenConfiguration {

    @Bean
    Clock tokenClock() {
        return Clock.systemUTC();
    }

    @Bean
    SecretKey tokenSigningKey(TokenProperties properties) {
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(properties.secret());
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException("AUTH_TOKEN_SECRET must be valid Base64.");
        }
        if (bytes.length < 32) {
            throw new IllegalArgumentException("AUTH_TOKEN_SECRET must decode to at least 32 bytes.");
        }
        return new SecretKeySpec(bytes, "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey key) {
        return NimbusJwtEncoder.withSecretKey(key).algorithm(MacAlgorithm.HS256).build();
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey key, TokenProperties properties, Clock clock) {
        var decoder = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
        var timestamps = new JwtTimestampValidator(Duration.ZERO);
        timestamps.setClock(clock);
        OAuth2TokenValidator<Jwt> claims = jwt -> {
            try {
                UUID.fromString(jwt.getSubject());
                if (jwt.getExpiresAt() != null && jwt.getIssuedAt() != null
                        && jwt.getExpiresAt().isAfter(clock.instant())
                        && jwt.getAudience().contains(properties.audience())
                        && "access".equals(jwt.getClaimAsString("token_use"))) {
                    return OAuth2TokenValidatorResult.success();
                }
            } catch (IllegalArgumentException | NullPointerException ignored) {
                // Reject missing or malformed application claims without exposing the token.
            }
            return OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token"));
        };
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                timestamps, new JwtIssuerValidator(properties.issuer()), claims));
        return decoder;
    }
}
