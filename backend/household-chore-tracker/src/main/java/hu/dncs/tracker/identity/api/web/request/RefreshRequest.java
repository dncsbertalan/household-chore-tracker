package hu.dncs.tracker.identity.api.web.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record RefreshRequest(@NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{43}") String refreshToken) {
    @Override
    public String toString() {
        return "RefreshRequest[redacted]";
    }
}
