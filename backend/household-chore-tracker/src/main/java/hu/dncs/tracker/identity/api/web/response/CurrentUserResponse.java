package hu.dncs.tracker.identity.api.web.response;

import hu.dncs.tracker.identity.domain.model.User;

import java.util.UUID;

public record CurrentUserResponse(UUID id, String email, String firstName, String lastName) {
    public static CurrentUserResponse from(User user) {
        return new CurrentUserResponse(user.getId(), user.getEmail(), user.getFirstName(), user.getLastName());
    }
}
