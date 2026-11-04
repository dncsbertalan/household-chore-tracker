package hu.dncs.tracker.chore.application.model;

public record ChoreActions(boolean canComplete, boolean canApprove, boolean canReject, boolean canCreateOccurrence) {}
