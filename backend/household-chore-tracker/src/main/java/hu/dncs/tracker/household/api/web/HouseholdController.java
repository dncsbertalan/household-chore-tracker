package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.api.web.request.CreateHouseholdRequest;
import hu.dncs.tracker.household.api.web.response.HouseholdResponse;
import hu.dncs.tracker.household.application.command.CreateHouseholdCommand;
import hu.dncs.tracker.household.application.usecase.CreateHouseholdUseCase;
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
    ResponseEntity<HouseholdResponse> create(@Valid @RequestBody CreateHouseholdRequest request, Authentication authentication) {
        var household = createHouseholdUseCase.execute(
                new CreateHouseholdCommand(request.householdId(), request.name(), request.description()),
                UUID.fromString(authentication.getName())
        );

        return ResponseEntity.created(URI.create("/api/v1/households/" + household.getHouseholdId()))
                .body(HouseholdResponse.from(household));
    }
}
