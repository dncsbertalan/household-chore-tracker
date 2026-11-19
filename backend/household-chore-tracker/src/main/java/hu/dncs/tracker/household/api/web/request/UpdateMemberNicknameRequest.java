package hu.dncs.tracker.household.api.web.request;

import hu.dncs.tracker.household.application.command.UpdateMemberNicknameCommand;
import jakarta.validation.constraints.*;

public record UpdateMemberNicknameRequest(@Size(max = 100) String nickname, @NotNull @Min(0) Long version) {
    public UpdateMemberNicknameCommand toCommand() { return new UpdateMemberNicknameCommand(nickname, version); }
}
