package hu.dncs.tracker.chore.application.model;

import hu.dncs.tracker.chore.domain.model.ChoreOccurrence;
import java.util.List;

public record ChoreDetails(CreatedChore current, List<ChoreOccurrence> occurrences) {}
