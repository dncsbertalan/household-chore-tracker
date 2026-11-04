package hu.dncs.tracker.chore.domain.model;

import java.time.*;
import java.time.temporal.ChronoUnit;

/** Calendar-based recurrence preserves fixed anchors across DST and short months. */
public final class ChoreRecurrence {
    private ChoreRecurrence() {}

    public static Instant nextScheduledAt(ChoreSchedule schedule, ChoreOccurrence current, Instant completedAt) {
        if (schedule.getScheduleType() == ChoreScheduleType.ON_DEMAND) return null;
        var unit = switch (schedule.getRecurrenceUnit()) {
            case HOUR -> ChronoUnit.HOURS;
            case DAY -> ChronoUnit.DAYS;
            case WEEK -> ChronoUnit.WEEKS;
            case MONTH -> ChronoUnit.MONTHS;
            case YEAR -> ChronoUnit.YEARS;
        };
        var zone = ZoneId.of(schedule.getTimeZoneIdentifier());
        if (schedule.getScheduleType() == ChoreScheduleType.AFTER_COMPLETION) {
            return completedAt.atZone(zone).plus(schedule.getRecurrenceInterval(), unit).toInstant();
        }
        var anchor = schedule.getZonedStartsAt();
        var cutoff = current.getScheduledAt() != null && current.getScheduledAt().isAfter(completedAt)
                ? current.getScheduledAt() : completedAt;
        if (anchor.toInstant().isAfter(cutoff)) return anchor.toInstant();
        long steps = Math.max(0, unit.between(anchor, cutoff.atZone(zone)) / schedule.getRecurrenceInterval());
        var next = anchor.plus(Math.multiplyExact(steps, schedule.getRecurrenceInterval()), unit);
        while (!next.toInstant().isAfter(cutoff)) {
            steps++;
            next = anchor.plus(Math.multiplyExact(steps, schedule.getRecurrenceInterval()), unit);
        }
        return next.toInstant();
    }

    public static Instant nextDueAt(ChoreOccurrence current, Instant nextScheduledAt) {
        if (current.getDueAt() == null) return null;
        var baseline = current.getScheduledAt() == null ? current.getCreatedAt() : current.getScheduledAt();
        var window = Duration.between(baseline, current.getDueAt());
        return nextScheduledAt.plus(window.isNegative() ? Duration.ZERO : window);
    }
}
