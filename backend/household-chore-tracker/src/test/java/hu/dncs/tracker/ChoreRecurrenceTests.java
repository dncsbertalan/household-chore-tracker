package hu.dncs.tracker;

import hu.dncs.tracker.chore.domain.model.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import static org.assertj.core.api.Assertions.assertThat;

class ChoreRecurrenceTests {
    @ParameterizedTest
    @EnumSource(ChoreRecurrenceUnit.class)
    void allUnitsFollowTheFixedAnchorAndCompletionRelativeRules(ChoreRecurrenceUnit unit) {
        var anchor = ZonedDateTime.of(2026, 1, 15, 9, 0, 0, 0, ZoneId.of("Europe/Budapest"));
        var scheduled = anchor.toInstant();
        var completed = scheduled.plusSeconds(300);
        var current = occurrence(scheduled, scheduled.plusSeconds(7200));
        var temporal = ChronoUnit.valueOf(unit == ChoreRecurrenceUnit.DAY ? "DAYS" : unit == ChoreRecurrenceUnit.MONTH ? "MONTHS"
                : unit == ChoreRecurrenceUnit.YEAR ? "YEARS" : unit == ChoreRecurrenceUnit.WEEK ? "WEEKS" : "HOURS");
        var fixed = schedule(ChoreScheduleType.FIXED, unit, 2, scheduled);
        assertThat(ChoreRecurrence.nextScheduledAt(fixed, current, completed)).isEqualTo(anchor.plus(2, temporal).toInstant());
        var after = schedule(ChoreScheduleType.AFTER_COMPLETION, unit, 2, null);
        assertThat(ChoreRecurrence.nextScheduledAt(after, current, completed)).isEqualTo(completed.atZone(anchor.getZone()).plus(2, temporal).toInstant());
        assertThat(ChoreRecurrence.nextDueAt(current, anchor.plus(2, temporal).toInstant())).isEqualTo(anchor.plus(2, temporal).toInstant().plusSeconds(7200));
    }

    @Test
    void fixedMonthlyAndYearlySchedulesDoNotDriftAfterShortMonths() {
        var january = Instant.parse("2026-01-31T08:00:00Z");
        var monthly = schedule(ChoreScheduleType.FIXED, ChoreRecurrenceUnit.MONTH, 1, january);
        var february = Instant.parse("2026-02-28T08:00:00Z");
        assertThat(ChoreRecurrence.nextScheduledAt(monthly, occurrence(february, null), february))
                .isEqualTo(Instant.parse("2026-03-31T07:00:00Z"));
        var leap = Instant.parse("2024-02-29T08:00:00Z");
        var yearly = schedule(ChoreScheduleType.FIXED, ChoreRecurrenceUnit.YEAR, 1, leap);
        assertThat(ChoreRecurrence.nextScheduledAt(yearly, occurrence(leap, null), Instant.parse("2027-03-01T08:00:00Z")))
                .isEqualTo(Instant.parse("2028-02-29T08:00:00Z"));
    }

    @Test
    void dailyRecurrenceReturnsToItsWallClockAnchorAfterTheSpringGap() {
        var anchor = Instant.parse("2026-03-28T01:30:00Z");
        var daily = schedule(ChoreScheduleType.FIXED, ChoreRecurrenceUnit.DAY, 1, anchor);
        var gap = ChoreRecurrence.nextScheduledAt(daily, occurrence(anchor, null), anchor);
        assertThat(gap).isEqualTo(Instant.parse("2026-03-29T01:30:00Z"));
        assertThat(ChoreRecurrence.nextScheduledAt(daily, occurrence(gap, null), gap))
                .isEqualTo(Instant.parse("2026-03-30T00:30:00Z"));
    }

    @Test
    void hourlyRecurrenceKeepsBothInstantsInTheRepeatedAutumnHour() {
        var anchor = Instant.parse("2026-10-25T00:30:00Z");
        var hourly = schedule(ChoreScheduleType.FIXED, ChoreRecurrenceUnit.HOUR, 1, anchor);
        assertThat(ChoreRecurrence.nextScheduledAt(hourly, occurrence(anchor, null), anchor)).isEqualTo(Instant.parse("2026-10-25T01:30:00Z"));
    }

    @Test
    void lateCompletionsSkipMissedSlotsAndEarlyCompletionsNeverRepeatTheCurrentSlot() {
        var anchor = Instant.parse("2026-11-01T08:00:00Z");
        var daily = schedule(ChoreScheduleType.FIXED, ChoreRecurrenceUnit.DAY, 1, anchor);
        assertThat(ChoreRecurrence.nextScheduledAt(daily, occurrence(anchor, null), Instant.parse("2026-11-10T09:00:00Z")))
                .isEqualTo(Instant.parse("2026-11-11T08:00:00Z"));
        assertThat(ChoreRecurrence.nextScheduledAt(daily, occurrence(Instant.parse("2026-11-12T08:00:00Z"), null), Instant.parse("2026-11-10T09:00:00Z")))
                .isEqualTo(Instant.parse("2026-11-13T08:00:00Z"));
    }

    private ChoreSchedule schedule(ChoreScheduleType type, ChoreRecurrenceUnit unit, int interval, Instant anchor) {
        return new ChoreSchedule(UUID.randomUUID(), UUID.randomUUID(), type, unit, interval, anchor, "Europe/Budapest", UUID.randomUUID());
    }
    private ChoreOccurrence occurrence(Instant scheduledAt, Instant dueAt) {
        var member = UUID.randomUUID();
        var chore = new Chore(UUID.randomUUID(), UUID.randomUUID(), "Chore", null, UUID.randomUUID(), member, List.of(member), 0);
        return new ChoreOccurrence(UUID.randomUUID(), chore, scheduledAt, dueAt, member);
    }
}
