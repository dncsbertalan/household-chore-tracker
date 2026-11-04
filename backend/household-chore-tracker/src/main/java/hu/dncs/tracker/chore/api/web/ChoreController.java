package hu.dncs.tracker.chore.api.web;

import hu.dncs.tracker.chore.application.usecase.GetChoreUseCase;
import hu.dncs.tracker.chore.application.usecase.UpdateChoreUseCase;
import hu.dncs.tracker.chore.api.web.request.UpdateChoreRequest;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;

import hu.dncs.tracker.chore.application.usecase.GetChoresUseCase;
import org.springframework.web.bind.annotation.GetMapping;
import java.util.List;

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

    private final GetChoresUseCase getChores;
    private final UpdateChoreUseCase updateChore;

    @PutMapping("/{id}")
    @Idempotent("chore.update")
    ChoreResponse update(@PathVariable UUID id,
                         @Valid @RequestBody UpdateChoreRequest request,
                         Authentication authentication) {
        return ChoreResponse.from(updateChore.execute(id, request.toCommand(), UUID.fromString(authentication.getName())));
    }

    private final GetChoreUseCase getChore;

    @GetMapping("/{id}")
    ChoreResponse one(@PathVariable UUID id, Authentication authentication) {
        return ChoreResponse.from(getChore.execute(id, UUID.fromString(authentication.getName())));
    }


    @GetMapping
    List<ChoreResponse> all(Authentication authentication) {
        return getChores.execute(UUID.fromString(authentication.getName()), null).stream().map(ChoreResponse::from).toList();
    }

    @PostMapping
    @Idempotent("chore.create")
    ResponseEntity<ChoreResponse> create(@Valid @RequestBody CreateChoreRequest request, Authentication authentication) {
        var created = createChoreUseCase.execute(request.toCommand(), UUID.fromString(authentication.getName()));
        return ResponseEntity.created(URI.create("/api/v1/chores/" + created.chore().getChoreId()))
                .body(ChoreResponse.from(created));
    }
}
