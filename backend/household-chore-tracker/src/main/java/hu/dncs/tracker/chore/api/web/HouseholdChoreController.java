package hu.dncs.tracker.chore.api.web;

import hu.dncs.tracker.chore.api.web.response.ChoreResponse;
import hu.dncs.tracker.chore.application.usecase.GetChoresUseCase;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.*;

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
