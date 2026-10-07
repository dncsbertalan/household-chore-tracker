package hu.dncs.tracker.identity.api.web.response;

import hu.dncs.tracker.identity.application.TokenPair;

public record TokenResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        long expiresIn,
        long refreshExpiresIn
) {
    public static TokenResponse from(TokenPair pair) {
        return new TokenResponse(pair.accessToken(), pair.refreshToken(), "Bearer",
                pair.expiresIn(), pair.refreshExpiresIn());
    }

    @Override
    public String toString() {
        return "TokenResponse[redacted]";
    }
}
