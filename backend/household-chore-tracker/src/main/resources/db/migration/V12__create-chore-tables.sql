CREATE TABLE chore
(
    chore_id                UUID                        NOT NULL PRIMARY KEY,
    household_id            UUID                        NOT NULL REFERENCES household (household_id),
    title                   VARCHAR(100)                NOT NULL,
    description             VARCHAR(500),
    created_by_user_id      UUID                        NOT NULL REFERENCES users (user_id),
    required_approval_count INTEGER                     NOT NULL CHECK (required_approval_count >= 0),
    updated_at              TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    created_at              TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    version                 BIGINT                      NOT NULL
);
CREATE INDEX ix_chore_household ON chore (household_id);

CREATE TABLE chore_assigned_member
(
    chore_id            UUID NOT NULL REFERENCES chore (chore_id) ON DELETE CASCADE,
    household_member_id UUID NOT NULL REFERENCES household_member (household_member_id),
    PRIMARY KEY (chore_id, household_member_id)
);

CREATE TABLE chore_schedule
(
    chore_schedule_id    UUID                        NOT NULL PRIMARY KEY,
    chore_id             UUID                        NOT NULL UNIQUE REFERENCES chore (chore_id) ON DELETE CASCADE,
    schedule_type        VARCHAR(30)                 NOT NULL CHECK (schedule_type IN ('fixed', 'afterCompletion', 'onDemand')),
    recurrence_unit      VARCHAR(10) CHECK (recurrence_unit IN ('hour', 'day', 'week', 'month', 'year')),
    recurrence_interval  INTEGER                     NOT NULL CHECK (recurrence_interval > 0),
    starts_at            TIMESTAMP(6) WITH TIME ZONE,
    time_zone_identifier VARCHAR(100)                NOT NULL,
    updated_at           TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    created_at           TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    version              BIGINT                      NOT NULL,
    CHECK ((schedule_type = 'onDemand' AND recurrence_unit IS NULL AND starts_at IS NULL)
        OR (schedule_type IN ('fixed', 'afterCompletion') AND recurrence_unit IS NOT NULL)),
    CHECK (schedule_type <> 'fixed' OR starts_at IS NOT NULL)
);

CREATE TABLE chore_occurrence
(
    chore_occurrence_id     UUID                        NOT NULL PRIMARY KEY,
    chore_id                UUID                        NOT NULL REFERENCES chore (chore_id) ON DELETE CASCADE,
    title                   VARCHAR(100)                NOT NULL,
    description             VARCHAR(500),
    required_approval_count INTEGER                     NOT NULL CHECK (required_approval_count >= 0),
    scheduled_at            TIMESTAMP(6) WITH TIME ZONE,
    due_at                  TIMESTAMP(6) WITH TIME ZONE,
    occurrence_status       VARCHAR(30)                 NOT NULL,
    updated_at              TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    created_at              TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    version                 BIGINT                      NOT NULL,
    CHECK (scheduled_at IS NULL OR due_at IS NULL OR due_at >= scheduled_at)
);
CREATE INDEX ix_chore_occurrence_chore ON chore_occurrence (chore_id);

CREATE TABLE chore_occurrence_assigned_member
(
    chore_occurrence_id UUID NOT NULL REFERENCES chore_occurrence (chore_occurrence_id) ON DELETE CASCADE,
    household_member_id UUID NOT NULL REFERENCES household_member (household_member_id),
    PRIMARY KEY (chore_occurrence_id, household_member_id)
);
