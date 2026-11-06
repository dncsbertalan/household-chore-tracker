package hu.dncs.tracker.identity.api;

import java.util.UUID;

public record UserInfo(UUID userId, String email, String firstName, String lastName) {}
