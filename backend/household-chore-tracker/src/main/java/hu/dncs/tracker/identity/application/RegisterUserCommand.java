package hu.dncs.tracker.identity.application;

public record RegisterUserCommand(String email, String password, String firtName, String lastName) {
    @Override
    public String toString() {
        return "RegisterUserCommand[redacted]";
    }
}
