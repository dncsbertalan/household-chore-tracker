package hu.dncs.tracker.identity.application.command;

public record LoginCommand(String email, String password) {
    @Override
    public String toString() {
        return "LoginCommand[redacted]";
    }
}
