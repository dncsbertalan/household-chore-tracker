package hu.dncs.tracker.identity.api.web.response;

import hu.dncs.tracker.identity.domain.model.User;

import java.util.UUID;

public record RegistrationResponse(UUID id, String email, String firstName, String lastName) {
    public static RegistrationResponse from(User user) {
        return new RegistrationResponse(user.getId(), user.getEmail(), user.getFirstName(), user.getLastName());
    }
}
