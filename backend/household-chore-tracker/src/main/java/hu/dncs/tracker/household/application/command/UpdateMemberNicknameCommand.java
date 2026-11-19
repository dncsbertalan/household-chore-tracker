package hu.dncs.tracker.household.application.command;

public record UpdateMemberNicknameCommand(String nickname, Long version) {}
