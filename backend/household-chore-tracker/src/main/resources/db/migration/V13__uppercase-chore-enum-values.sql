-- Replace checks from V12 before converting existing values.
ALTER TABLE chore_schedule
    DROP CONSTRAINT chore_schedule_schedule_type_check,
    DROP CONSTRAINT chore_schedule_recurrence_unit_check,
    DROP CONSTRAINT chore_schedule_check,
    DROP CONSTRAINT chore_schedule_check1;

UPDATE chore_schedule
SET schedule_type   = CASE schedule_type
                          WHEN 'fixed' THEN 'FIXED'
                          WHEN 'afterCompletion' THEN 'AFTER_COMPLETION'
                          WHEN 'onDemand' THEN 'ON_DEMAND'
                          ELSE schedule_type
    END,
    recurrence_unit = UPPER(recurrence_unit);

ALTER TABLE chore_schedule
    ADD CONSTRAINT chore_schedule_schedule_type_check
        CHECK (schedule_type IN ('FIXED', 'AFTER_COMPLETION', 'ON_DEMAND')),
    ADD CONSTRAINT chore_schedule_recurrence_unit_check
        CHECK (recurrence_unit IN ('HOUR', 'DAY', 'WEEK', 'MONTH', 'YEAR')),
    ADD CONSTRAINT chore_schedule_recurrence_configuration_check
        CHECK ((schedule_type = 'ON_DEMAND' AND recurrence_unit IS NULL AND starts_at IS NULL)
            OR (schedule_type IN ('FIXED', 'AFTER_COMPLETION') AND recurrence_unit IS NOT NULL)),
    ADD CONSTRAINT chore_schedule_fixed_start_check
        CHECK (schedule_type <> 'FIXED' OR starts_at IS NOT NULL);
