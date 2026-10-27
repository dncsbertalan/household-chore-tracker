package hu.dncs.tracker.household.application.command;

import java.util.UUID;

public record InviteHouseholdMemberCommand(
        String email,
        UUID householdRoleId
) {
}
