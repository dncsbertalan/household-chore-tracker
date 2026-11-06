package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.application.HouseholdRoleManagementService;
import hu.dncs.tracker.household.api.web.request.*;
import hu.dncs.tracker.household.api.web.response.HouseholdRolesResponse;
import hu.dncs.tracker.household.api.web.response.HouseholdMemberRemovalResponse;
import hu.dncs.tracker.idempotency.api.web.Idempotent;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/households/{householdId}")
@RequiredArgsConstructor
class HouseholdRoleController {
    private final HouseholdResponseMapper responses;
    private final HouseholdRoleManagementService service;
    @GetMapping("/roles")
    HouseholdRolesResponse get(@PathVariable UUID householdId, Authentication auth) {
        return responses.from(service.get(householdId, user(auth)));
    }
    @PostMapping("/roles")
    @Idempotent("household.role.create")
    ResponseEntity<HouseholdRolesResponse> create(@PathVariable UUID householdId, @Valid @RequestBody SaveHouseholdRoleRequest request, Authentication auth) {
        return ResponseEntity.status(HttpStatus.CREATED).body(responses.from(service.create(householdId, request.toCommand(null), user(auth))));
    }
    @PutMapping("/roles/{roleId}")
    @Idempotent("household.role.update")
    HouseholdRolesResponse update(@PathVariable UUID householdId, @PathVariable UUID roleId, @Valid @RequestBody UpdateHouseholdRoleRequest request, Authentication auth) {
        return responses.from(service.update(householdId, roleId, request.toCommand(), user(auth)));
    }
    @DeleteMapping("/roles/{roleId}")
    @Idempotent("household.role.delete")
    HouseholdRolesResponse delete(@PathVariable UUID householdId, @PathVariable UUID roleId, @RequestParam @Min(0) Long version, Authentication auth) {
        return responses.from(service.delete(householdId, roleId, version, user(auth)));
    }
    @PutMapping("/members/{memberId}/role")
    @Idempotent("household.member.assign-role")
    HouseholdRolesResponse assign(@PathVariable UUID householdId, @PathVariable UUID memberId, @Valid @RequestBody AssignHouseholdRoleRequest request, Authentication auth) {
        return responses.from(service.assign(householdId, memberId, request.roleId(), request.memberVersion(), request.roleVersion(), user(auth)));
    }
    @DeleteMapping("/members/{memberId}")
    @Idempotent("household.member.remove")
    HouseholdMemberRemovalResponse removeMember(@PathVariable UUID householdId,
            @PathVariable UUID memberId, @RequestParam @Min(0) Long version, Authentication auth) {
        return responses.from(
                service.removeMember(householdId, memberId, version, user(auth)));
    }
    private UUID user(Authentication auth) { return UUID.fromString(auth.getName()); }
}
