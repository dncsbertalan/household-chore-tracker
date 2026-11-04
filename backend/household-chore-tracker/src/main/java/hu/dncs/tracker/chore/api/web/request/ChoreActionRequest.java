package hu.dncs.tracker.chore.api.web.request;

import jakarta.validation.constraints.*;

public record ChoreActionRequest(@NotNull @Min(0) Long version, @Min(0) Long occurrenceVersion,
                                 @Min(0) Long completionVersion) {}
