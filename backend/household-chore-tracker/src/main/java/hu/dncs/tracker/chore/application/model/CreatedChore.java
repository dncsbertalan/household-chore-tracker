package hu.dncs.tracker.chore.application.model;

import hu.dncs.tracker.chore.domain.model.*;

public record CreatedChore(Chore chore, ChoreSchedule schedule, ChoreOccurrence occurrence) {}
