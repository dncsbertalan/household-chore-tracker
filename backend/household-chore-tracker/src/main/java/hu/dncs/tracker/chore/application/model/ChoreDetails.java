package hu.dncs.tracker.chore.application.model;

import hu.dncs.tracker.chore.domain.model.*;
import java.util.List;

public record ChoreDetails(CreatedChore current, List<ChoreOccurrence> occurrences,
                           List<ChoreCompletion> completions, List<ChoreApproval> approvals, ChoreActions actions) {}
