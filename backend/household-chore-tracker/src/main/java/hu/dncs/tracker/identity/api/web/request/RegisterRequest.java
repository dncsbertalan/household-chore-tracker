package hu.dncs.tracker.identity.api.web.request;

import hu.dncs.tracker.identity.domain.model.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank @Email @Size(max = 255) String email,
        @NotBlank @Size(min = 12, max = 128) String password,
        @NotBlank @Size(max = 100) String firstName,
        @NotBlank @Size(max = 100) String lastName
) {
    public RegisterRequest {
        email = User.normalizeEmail(email);
        firstName = firstName == null ? null : firstName.strip();
        lastName = lastName == null ? null : lastName.strip();
    }

    @Override
    public String toString() {
        return "RegisterRequest[redacted]";
    }
}
