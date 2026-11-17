package hu.dncs.tracker.household.api.web;

import hu.dncs.tracker.household.api.web.response.HouseholdInvitationDto;
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
    private final HouseholdResponseMapper responses;
    private final HouseholdInvitationService householdInvitationService;

    @GetMapping
    List<HouseholdInvitationDto> inbox(@CurrentUserId UUID userId) {
        return householdInvitationService.inbox(userId).stream().map(HouseholdInvitationDto::from).toList();
    }

    @GetMapping("/{invitationId}")
    HouseholdInvitationDto get(@PathVariable UUID invitationId, @CurrentUserId UUID userId) {
        return HouseholdInvitationDto.from(householdInvitationService.get(invitationId, userId));
    }

    @PostMapping("/{invitationId}/accept")
    @Idempotent("household.invitation.accept")
    void accept(@PathVariable UUID invitationId, @CurrentUserId UUID userId) {
        householdInvitationService.accept(invitationId, userId);
    }

    @PostMapping("/{invitationId}/decline")
    @Idempotent("household.invitation.decline")
    void decline(@PathVariable UUID invitationId, @CurrentUserId UUID userId) {
        householdInvitationService.decline(invitationId, userId);
    }
}
