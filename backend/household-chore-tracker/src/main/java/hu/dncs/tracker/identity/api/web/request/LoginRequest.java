package hu.dncs.tracker.identity.api.web.request;

import hu.dncs.tracker.identity.domain.model.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(@NotBlank @Email @Size(max = 255) String email,
                           @NotBlank @Size(max = 128) String password) {
    public LoginRequest {
        email = User.normalizeEmail(email);
    }

    @Override
    public String toString() {
        return "LoginRequest[redacted]";
    }
}
