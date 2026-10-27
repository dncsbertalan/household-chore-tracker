package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.api.web.response.HouseholdInvitationResponse;
import hu.dncs.tracker.household.api.web.response.JoinedHouseholdResponse;
import hu.dncs.tracker.household.application.HouseholdInvitationService;
import hu.dncs.tracker.idempotency.api.web.Idempotent;
import hu.dncs.tracker.identity.api.web.CurrentUserId;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/household-invitations")
@RequiredArgsConstructor
class InvitationInboxController {
    private final HouseholdInvitationService householdInvitationService;

    @GetMapping
    List<HouseholdInvitationResponse> inbox(@CurrentUserId UUID userId) {
        return householdInvitationService.inbox(userId).stream().map(HouseholdInvitationResponse::from).toList();
    }

    @GetMapping("/{invitationId}")
    HouseholdInvitationResponse get(@PathVariable UUID invitationId, @CurrentUserId UUID userId) {
        return HouseholdInvitationResponse.from(householdInvitationService.get(invitationId, userId));
    }

    @PostMapping("/{invitationId}/accept")
    @Idempotent("household.invitation.accept")
    JoinedHouseholdResponse accept(@PathVariable UUID invitationId, @CurrentUserId UUID userId) {
        return JoinedHouseholdResponse.from(householdInvitationService.accept(invitationId, userId));
    }

    @PostMapping("/{invitationId}/decline")
    @Idempotent("household.invitation.decline")
    HouseholdInvitationResponse decline(@PathVariable UUID invitationId, @CurrentUserId UUID userId) {
        return HouseholdInvitationResponse.from(householdInvitationService.decline(invitationId, userId));
    }
}
