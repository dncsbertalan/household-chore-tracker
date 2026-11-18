package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.usecase.GetHouseholdsUseCase;
import hu.dncs.tracker.household.application.usecase.UpdateHouseholdUseCase;
import hu.dncs.tracker.household.api.web.request.UpdateHouseholdRequest;
import org.springframework.web.bind.annotation.PutMapping;
import hu.dncs.tracker.household.application.usecase.DeleteHouseholdUseCase;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestParam;
import jakarta.validation.constraints.Min;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import java.util.List;

import hu.dncs.tracker.household.api.web.request.CreateHouseholdRequest;
import hu.dncs.tracker.household.api.web.response.HouseholdResponse;
import hu.dncs.tracker.household.api.web.response.HouseholdSummaryResponse;
import hu.dncs.tracker.household.application.createhousehold.CreateHouseholdCommand;
import hu.dncs.tracker.household.application.createhousehold.CreateHouseholdRoleCommand;
import hu.dncs.tracker.household.application.createhousehold.CreateHouseholdUseCase;
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
    private final HouseholdResponseMapper householdResponseMapper;
    private final CreateHouseholdUseCase createHouseholdUseCase;

    private final GetHouseholdsUseCase getHouseholdsUseCase;
    private final DeleteHouseholdUseCase deleteHouseholdUseCase;
    private final UpdateHouseholdUseCase updateHouseholdUseCase;

    @PutMapping("/{id}")
    @Idempotent("household.update")
    HouseholdResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateHouseholdRequest request, Authentication authentication) {
        return householdResponseMapper.from(updateHouseholdUseCase.execute(id, request.toCommand(), UUID.fromString(authentication.getName())), UUID.fromString(authentication.getName()));
    }

    @DeleteMapping("/{id}")
    @Idempotent("household.delete")
    ResponseEntity<Void> delete(@PathVariable UUID id, @RequestParam @Min(0) Long version,
            @RequestParam(defaultValue = "false") boolean confirmed, Authentication authentication) {
        deleteHouseholdUseCase.execute(id, version, confirmed, UUID.fromString(authentication.getName()));
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    List<HouseholdResponse> all(Authentication authentication) {
        return householdResponseMapper.from(getHouseholdsUseCase.all(UUID.fromString(authentication.getName())), UUID.fromString(authentication.getName()));
    }

    @GetMapping("/summaries")
    List<HouseholdSummaryResponse> summaries(Authentication authentication) {
        return householdResponseMapper.summaries(getHouseholdsUseCase.all(UUID.fromString(authentication.getName())));
    }

    @GetMapping("/{id}")
    HouseholdResponse one(@PathVariable UUID id, Authentication authentication) {
        return householdResponseMapper.from(getHouseholdsUseCase.one(id, UUID.fromString(authentication.getName())), UUID.fromString(authentication.getName()));
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
                .body(householdResponseMapper.from(created));
    }
}
