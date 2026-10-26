package hu.dncs.tracker.household.api.web;

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
