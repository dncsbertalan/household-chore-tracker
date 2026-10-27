package hu.dncs.tracker.household.api.web.request;

import hu.dncs.tracker.household.application.command.InviteHouseholdMemberCommand;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.Locale;
import java.util.UUID;

public record InviteHouseholdMemberRequest(
        @NotBlank @Email @Size(max = 255) String email,
        @NotNull UUID householdRoleId
) {
    public InviteHouseholdMemberRequest {
        email = email == null ? null : email.strip().toLowerCase(Locale.ROOT);
    }

    public InviteHouseholdMemberCommand toCommand() {
        return new InviteHouseholdMemberCommand(email, householdRoleId);
    }
}
