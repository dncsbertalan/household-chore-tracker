package hu.dncs.tracker.identity.infrastructure.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@ConfigurationProperties("identity.tokens")
public record TokenProperties(String secret, String issuer, String audience,
                              Duration accessTtl, Duration refreshTtl) {
    public TokenProperties {
        if (secret == null || secret.isBlank()) {
            throw new IllegalArgumentException("Set AUTH_TOKEN_SECRET to a Base64-encoded random key of at least 32 bytes.");
        }
        if (issuer == null || issuer.isBlank() || audience == null || audience.isBlank()) {
            throw new IllegalArgumentException("Token issuer and audience must be configured.");
        }
        if (accessTtl == null || accessTtl.compareTo(Duration.ofSeconds(1)) < 0
                || refreshTtl == null || refreshTtl.compareTo(accessTtl) <= 0) {
            throw new IllegalArgumentException("Token lifetimes must be positive, with refresh TTL greater than access TTL.");
        }
    }

    @Override
    public String toString() {
        return "TokenProperties[redacted]";
    }
}
