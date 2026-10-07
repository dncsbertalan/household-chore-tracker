package hu.dncs.tracker.identity.api.web;

import hu.dncs.tracker.identity.api.web.response.CurrentUserResponse;
import hu.dncs.tracker.identity.application.usecase.GetCurrentUserUseCase;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
class UserController {
    private final GetCurrentUserUseCase getCurrentUser;

    @GetMapping("/me")
    ResponseEntity<CurrentUserResponse> me(Authentication authentication) {
        // The resource server validates the JWT subject as a UUID before this adapter runs.
        var user = getCurrentUser.execute(UUID.fromString(authentication.getName()));
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(CurrentUserResponse.from(user));
    }
}
