package hu.dncs.tracker.identity.application;

public record TokenPair(String accessToken, String refreshToken, long expiresIn, long refreshExpiresIn) {
    @Override
    public String toString() {
        return "TokenPair[redacted]";
    }
}
