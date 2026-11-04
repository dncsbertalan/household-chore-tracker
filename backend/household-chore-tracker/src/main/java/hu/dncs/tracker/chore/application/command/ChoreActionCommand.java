package hu.dncs.tracker.chore.application.command;

public record ChoreActionCommand(Long version, Long occurrenceVersion, Long completionVersion) {}
