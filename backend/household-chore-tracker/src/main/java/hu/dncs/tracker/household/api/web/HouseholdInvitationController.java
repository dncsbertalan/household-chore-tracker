package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.api.web.request.InviteHouseholdMemberRequest;
import hu.dncs.tracker.household.api.web.response.HouseholdInvitationDto;
import hu.dncs.tracker.household.application.HouseholdInvitationService;
import hu.dncs.tracker.idempotency.api.web.Idempotent;
import hu.dncs.tracker.identity.api.web.CurrentUserId;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/households/{householdId}/invitations")
@RequiredArgsConstructor
class HouseholdInvitationController {
    private final HouseholdInvitationService householdInvitationService;

    @PostMapping
    @Idempotent("household.invitation.create")
    ResponseEntity<HouseholdInvitationDto> invite(@PathVariable UUID householdId,
                                                  @Valid @RequestBody InviteHouseholdMemberRequest request, @CurrentUserId UUID userId) {
        var invitation = householdInvitationService.invite(householdId, request.toCommand(), userId);
        return ResponseEntity.created(URI.create("/api/v1/household-invitations/" + invitation.householdInvitationId()))
                .body(HouseholdInvitationDto.from(invitation));
    }

    @GetMapping
    List<HouseholdInvitationDto> forHousehold(@PathVariable UUID householdId, @CurrentUserId UUID userId) {
        return householdInvitationService.forHousehold(householdId, userId).stream()
                .map(HouseholdInvitationDto::from).toList();
    }

    @DeleteMapping("/{invitationId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Idempotent("household.invitation.revoke")
    void revoke(@PathVariable UUID householdId, @PathVariable UUID invitationId, @CurrentUserId UUID userId) {
        householdInvitationService.revoke(householdId, invitationId, userId);
    }
}
