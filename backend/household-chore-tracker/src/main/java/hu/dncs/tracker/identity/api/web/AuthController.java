package hu.dncs.tracker.identity.api.web;

import hu.dncs.tracker.identity.api.web.request.LoginRequest;
import hu.dncs.tracker.identity.api.web.request.RefreshRequest;
import hu.dncs.tracker.identity.api.web.request.RegisterRequest;
import hu.dncs.tracker.identity.api.web.response.RegistrationResponse;
import hu.dncs.tracker.identity.api.web.response.TokenResponse;
import hu.dncs.tracker.identity.application.command.LoginCommand;
import hu.dncs.tracker.identity.application.command.RegisterUserCommand;
import hu.dncs.tracker.identity.application.usecase.LoginUseCase;
import hu.dncs.tracker.identity.application.usecase.RefreshTokensUseCase;
import hu.dncs.tracker.identity.application.usecase.RegisterUserUseCase;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
class AuthController {

    private final RegisterUserUseCase registerUser;
    private final LoginUseCase login;
    private final RefreshTokensUseCase refreshTokens;

    @GetMapping("/csrf")
    CsrfToken csrf(CsrfToken token) {
        return token;
    }

    @PostMapping("/login")
    ResponseEntity<TokenResponse> login(@Valid @RequestBody LoginRequest request) {
        var result = login.execute(new LoginCommand(request.email(), request.password()));
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(TokenResponse.from(result));
    }

    @PostMapping("/refresh")
    ResponseEntity<TokenResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        var result = refreshTokens.execute(request.refreshToken());
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(TokenResponse.from(result));
    }

    @PostMapping("/register")
    ResponseEntity<RegistrationResponse> register(@Valid @RequestBody RegisterRequest request) {
        var result = registerUser.execute(new RegisterUserCommand(request.email(), request.password(), request.firstName(), request.lastName()));

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(RegistrationResponse.from(result));
    }
}
