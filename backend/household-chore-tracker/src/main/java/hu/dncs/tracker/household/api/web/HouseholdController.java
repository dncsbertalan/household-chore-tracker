package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.usecase.GetHouseholdsUseCase;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import java.util.List;

import hu.dncs.tracker.household.api.web.request.CreateHouseholdRequest;
import hu.dncs.tracker.household.api.web.response.HouseholdResponse;
import hu.dncs.tracker.household.application.command.CreateHouseholdCommand;
import hu.dncs.tracker.household.application.command.CreateHouseholdRoleCommand;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
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
@RequestMapping("/api/v1/households")
@RequiredArgsConstructor
class HouseholdController {
    private final CreateHouseholdUseCase createHouseholdUseCase;

    private final GetHouseholdsUseCase getHouseholds;

    @GetMapping
    List<HouseholdResponse> all(Authentication authentication) {
        return getHouseholds.all(UUID.fromString(authentication.getName())).stream().map(HouseholdResponse::from).toList();
    }

    @GetMapping("/{id}")
    HouseholdResponse one(@PathVariable UUID id, Authentication authentication) {
        return HouseholdResponse.from(getHouseholds.one(id, UUID.fromString(authentication.getName())));
    }

    @PostMapping
    @Idempotent("household.create")
    ResponseEntity<HouseholdResponse> create(@Valid @RequestBody CreateHouseholdRequest request, Authentication authentication) {
        var created = createHouseholdUseCase.execute(
                new CreateHouseholdCommand(request.householdId(), request.name(), request.description(),
                        request.roles().stream()
                                .map(role -> new CreateHouseholdRoleCommand(role.householdRoleId(), role.name(), role.permissions()))
                                .toList(),
                        request.creatorRoleId(), request.householdMemberId()),
                UUID.fromString(authentication.getName())
        );

        return ResponseEntity.created(URI.create("/api/v1/households/" + created.household().getHouseholdId()))
                .body(HouseholdResponse.from(created));
    }
}
