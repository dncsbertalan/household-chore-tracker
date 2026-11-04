package hu.dncs.tracker.chore.api.web;

import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import hu.dncs.tracker.chore.application.usecase.GetChoresUseCase;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/households/{householdId}/chores")
@RequiredArgsConstructor
class HouseholdChoreController {
    private final GetChoresUseCase getChores;

    @GetMapping
    List<ChoreResponse> all(@PathVariable UUID householdId, Authentication authentication) {
        return getChores.execute(UUID.fromString(authentication.getName()), householdId).stream().map(ChoreResponse::from).toList();
    }
}
