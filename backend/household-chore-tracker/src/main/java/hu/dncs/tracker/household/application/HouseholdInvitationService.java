package hu.dncs.tracker.household.application;

import hu.dncs.tracker.household.application.command.InviteHouseholdMemberCommand;
import hu.dncs.tracker.household.application.exception.HouseholdInvitationException;
import hu.dncs.tracker.household.application.model.HouseholdInvitationDetails;
import hu.dncs.tracker.household.application.model.JoinedHousehold;
import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdInvitation;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdInvitationRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdMemberRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRoleRepository;
import hu.dncs.tracker.identity.api.UserLookup;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static hu.dncs.tracker.household.application.exception.HouseholdInvitationException.Reason.*;
import static hu.dncs.tracker.household.domain.model.HouseholdInvitationStatus.*;
import static hu.dncs.tracker.household.domain.model.HouseholdInvitationStatus.EXPIRED;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.HOUSEHOLD_MEMBER_INVITE;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HouseholdInvitationService {
    private static final Duration INVITATION_TTL = Duration.ofDays(7);

    private final HouseholdInvitationRepository householdInvitationRepository;
    private final HouseholdRepository householdRepository;
    private final HouseholdRoleRepository householdRoleRepository;
    private final HouseholdMemberRepository householdMemberRepository;
    private final HouseholdAuthorizationService householdAuthorizationService;
    private final UserLookup userLookup;
    private final Clock clock;

    private static void requirePending(HouseholdInvitation invitation, Instant now) {
        if (invitation.statusAt(now) == EXPIRED) {
            throw new HouseholdInvitationException(HouseholdInvitationException.Reason.EXPIRED, "This invitation has expired.");
        }
        if (invitation.getStatus() != PENDING) {
            throw new HouseholdInvitationException(CONFLICT, "This invitation has already been answered or revoked.");
        }
    }

    private static HouseholdInvitationException notFound() {
        return new HouseholdInvitationException(NOT_FOUND, "Invitation not found.");
    }

    @Transactional
    public HouseholdInvitationDetails invite(UUID householdId, InviteHouseholdMemberCommand command, UUID callerId) {
        requireEmail(callerId);

        householdAuthorizationService.requirePermission(householdId, callerId, HOUSEHOLD_MEMBER_INVITE);

        var household = lockHousehold(householdId);
        var role = householdRoleRepository.findById(command.householdRoleId())
                .filter(candidate -> householdId.equals(candidate.getHouseholdId()))
                .orElseThrow(() -> new HouseholdInvitationException(INVALID_REQUEST, "The invited role must belong to this household."));

        userLookup.findUserIdByEmail(command.email()).ifPresent(userId -> requireNotMember(householdId, userId));

        var now = clock.instant();
        householdInvitationRepository.findPending(householdId, command.email())
                .ifPresent(existing -> {
                    if (existing.statusAt(now) == PENDING) {
                        throw new HouseholdInvitationException(CONFLICT, "A pending invitation already exists for this email.");
                    }
                    existing.respond(EXPIRED, now);
                    // Release the partial unique index before inserting a replacement.
                    householdInvitationRepository.flush();
                });

        var invitation = householdInvitationRepository.saveAndFlush(new HouseholdInvitation(UUID.randomUUID(), household,
                command.email(), callerId, role, now, now.plus(INVITATION_TTL)));

        return HouseholdInvitationDetails.from(invitation, now);
    }

    public List<HouseholdInvitationDetails> inbox(UUID callerId) {
        var email = requireEmail(callerId);
        var now = clock.instant();
        return householdInvitationRepository.findInbox(email, now).stream()
                .map(invitation -> HouseholdInvitationDetails.from(invitation, now)).toList();
    }

    public HouseholdInvitationDetails get(UUID invitationId, UUID callerId) {
        var invitation = requireRecipient(invitationId, requireEmail(callerId));
        return HouseholdInvitationDetails.from(invitation, clock.instant());
    }

    public List<HouseholdInvitationDetails> forHousehold(UUID householdId, UUID callerId) {
        requireEmail(callerId);
        householdAuthorizationService.requirePermission(householdId, callerId, HOUSEHOLD_MEMBER_INVITE);
        var now = clock.instant();
        return householdInvitationRepository.findForHousehold(householdId).stream()
                .map(invitation -> HouseholdInvitationDetails.from(invitation, now)).toList();
    }

    @Transactional
    public JoinedHousehold accept(UUID invitationId, UUID callerId) {
        var invitation = lockRecipientInvitation(invitationId, callerId);

        var now = clock.instant();
        requirePending(invitation, now);

        var household = invitation.getHousehold();
        requireNotMember(household.getHouseholdId(), callerId);

        var membership = householdMemberRepository.saveAndFlush(new HouseholdMember(UUID.randomUUID(), household,
                callerId, invitation.getHouseholdRole()));
        invitation.respond(ACCEPTED, now);
        householdInvitationRepository.flush();

        // Include the complete role catalog so a newly joined household can be stored by the client.
        return new JoinedHousehold(household,
                householdRoleRepository.findAllByHouseholdIdOrderByCreatedAtAscHouseholdRoleIdAsc(household.getHouseholdId()), membership);
    }

    @Transactional
    public HouseholdInvitationDetails decline(UUID invitationId, UUID callerId) {
        var invitation = lockRecipientInvitation(invitationId, callerId);

        var now = clock.instant();
        requirePending(invitation, now);
        invitation.respond(DECLINED, now);

        householdInvitationRepository.flush();

        return HouseholdInvitationDetails.from(invitation, now);
    }

    @Transactional
    public void revoke(UUID householdId, UUID invitationId, UUID callerId) {
        requireEmail(callerId);

        householdAuthorizationService.requirePermission(householdId, callerId, HOUSEHOLD_MEMBER_INVITE);

        lockHousehold(householdId);

        var invitation = householdInvitationRepository.findById(invitationId)
                .filter(candidate -> householdId.equals(candidate.getHousehold().getHouseholdId()))
                .orElseThrow(HouseholdInvitationService::notFound);
        var now = clock.instant();
        requirePending(invitation, now);
        invitation.respond(REVOKED, now);
        
        householdInvitationRepository.flush();
    }

    private HouseholdInvitation lockRecipientInvitation(UUID invitationId, UUID callerId) {
        var email = requireEmail(callerId);
        // Read a scalar first, avoiding a stale entity in the persistence context while waiting for the lock.
        var householdId = householdInvitationRepository.findHouseholdId(invitationId)
                .orElseThrow(HouseholdInvitationService::notFound);
        lockHousehold(householdId);
        return requireRecipient(invitationId, email);
    }

    private HouseholdInvitation requireRecipient(UUID invitationId, String email) {
        return householdInvitationRepository.findById(invitationId)
                .filter(invitation -> email.equals(invitation.getEmail()))
                .orElseThrow(HouseholdInvitationService::notFound);
    }

    private Household lockHousehold(UUID householdId) {
        return householdRepository.findForUpdate(householdId).orElseThrow(HouseholdInvitationService::notFound);
    }

    private String requireEmail(UUID userId) {
        return userLookup.findEmailByUserId(userId).orElseThrow(() ->
                new AuthenticationCredentialsNotFoundException("The authenticated account is no longer available."));
    }

    private void requireNotMember(UUID householdId, UUID userId) {
        if (householdMemberRepository.findByHousehold_HouseholdIdAndUserId(householdId, userId).isPresent()) {
            throw new HouseholdInvitationException(CONFLICT, "This account is already a household member.");
        }
    }
}
