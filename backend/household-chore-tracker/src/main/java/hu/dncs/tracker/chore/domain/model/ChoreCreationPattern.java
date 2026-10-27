package hu.dncs.tracker.chore.domain.model;

public enum ChoreCreationPattern {
    ONCE,
    FIXED,
    AFTER_COMPLETION,
    ON_DEMAND;

    public ChoreScheduleType scheduleType() {
        return switch (this) {
            case ONCE -> null;
            case FIXED -> ChoreScheduleType.FIXED;
            case AFTER_COMPLETION -> ChoreScheduleType.AFTER_COMPLETION;
            case ON_DEMAND -> ChoreScheduleType.ON_DEMAND;
        };
    }
}
