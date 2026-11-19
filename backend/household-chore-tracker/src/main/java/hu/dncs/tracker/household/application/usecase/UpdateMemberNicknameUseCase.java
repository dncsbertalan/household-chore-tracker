package hu.dncs.tracker.household.application.usecase;

import hu.dncs.tracker.household.application.command.UpdateMemberNicknameCommand;
import hu.dncs.tracker.household.application.exception.HouseholdRoleManagementException;
import hu.dncs.tracker.household.domain.model.Household;
import hu.dncs.tracker.household.domain.model.HouseholdMember;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Objects;
import java.util.UUID;
import static hu.dncs.tracker.household.application.exception.HouseholdRoleManagementException.Reason.*;

@Service
@RequiredArgsConstructor
public class UpdateMemberNicknameUseCase {
    private final HouseholdRepository households;
    private final HouseholdMemberRepository members;

    @Transactional
    public HouseholdMember execute(UUID householdId, UUID memberId, UpdateMemberNicknameCommand command, UUID userId) {
        households.findForUpdate(householdId).orElseThrow(() -> new HouseholdRoleManagementException(NOT_FOUND, "Household not found."));
        members.findByHousehold_HouseholdIdAndUserId(householdId, userId)
                .orElseThrow(() -> new AccessDeniedException("Household membership is required."));
        var target = members.findAllByHousehold_HouseholdId(householdId).stream()
                .filter(member -> member.getHouseholdMemberId().equals(memberId)).findFirst()
                .orElseThrow(() -> new HouseholdRoleManagementException(NOT_FOUND, "Member not found."));
        if (command.version() == null || !Objects.equals(command.version(), target.getVersion())) {
            throw new HouseholdRoleManagementException(STALE, "This member has changed. Reload before saving.");
        }
        var nickname = Household.trimmedText(command.nickname());
        if (nickname.length() > 100) throw new HouseholdRoleManagementException(INVALID, "Nickname must be at most 100 characters.");
        target.updateNickname(nickname);
        members.flush();
        return target;
    }
}
