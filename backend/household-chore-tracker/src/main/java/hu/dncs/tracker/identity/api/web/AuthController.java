package hu.dncs.tracker.identity.api.web;

import hu.dncs.tracker.identity.api.web.request.RegisterRequest;
import hu.dncs.tracker.identity.api.web.response.RegistrationResponse;
import hu.dncs.tracker.identity.application.RegisterUserCommand;
import hu.dncs.tracker.identity.application.RegisterUserUseCase;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
class AuthController {

    private final RegisterUserUseCase registerUser;

    @GetMapping("/csrf")
    CsrfToken csrf(CsrfToken token) {
        return token;
    }

    @PostMapping("/register")
    ResponseEntity<RegistrationResponse> register(@Valid @RequestBody RegisterRequest request) {
        var result = registerUser.execute(new RegisterUserCommand(request.email(), request.password(), request.firstName(), request.lastName()));

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(RegistrationResponse.from(result));
    }
}
