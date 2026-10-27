package hu.dncs.tracker.chore.api.web;

import hu.dncs.tracker.chore.api.web.request.CreateChoreRequest;
import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import hu.dncs.tracker.chore.application.usecase.CreateChoreUseCase;
import hu.dncs.tracker.idempotency.api.web.Idempotent;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/chores")
@RequiredArgsConstructor
class ChoreController {
    private final CreateChoreUseCase createChoreUseCase;

    @PostMapping
    @Idempotent("chore.create")
    ResponseEntity<ChoreResponse> create(@Valid @RequestBody CreateChoreRequest request, Authentication authentication) {
        var created = createChoreUseCase.execute(request.toCommand(), UUID.fromString(authentication.getName()));
        return ResponseEntity.created(URI.create("/api/v1/chores/" + created.chore().getChoreId()))
                .body(ChoreResponse.from(created));
    }
}
