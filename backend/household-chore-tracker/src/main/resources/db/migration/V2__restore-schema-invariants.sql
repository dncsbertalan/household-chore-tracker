-- ORM schema generation does not include application seed data or defaults used
-- by native SQL. Keep the generated V1 unchanged for databases that applied it.
ALTER TABLE processed_request
    ALTER COLUMN created_at SET DEFAULT CURRENT_TIMESTAMP,
    ALTER COLUMN response_content_type TYPE TEXT,
    ALTER COLUMN response_location TYPE TEXT,
    ALTER COLUMN response_etag TYPE TEXT,
    ADD CONSTRAINT fk_processed_request_account FOREIGN KEY (account_id) REFERENCES users(user_id) ON DELETE CASCADE,
    ADD CONSTRAINT ck_processed_request_response CHECK (
        (response_status IS NULL AND response_content_type IS NULL AND response_location IS NULL
            AND response_etag IS NULL AND response_body IS NULL)
        OR (response_status IS NOT NULL AND response_status BETWEEN 200 AND 299 AND response_body IS NOT NULL)
    );

INSERT INTO permission (name, description)
VALUES ('HOUSEHOLD_DELETE', 'Delete the household.'),
       ('HOUSEHOLD_MEMBER_VIEW', 'View household members.'),
       ('HOUSEHOLD_MEMBER_INVITE', 'Invite users to the household.'),
       ('HOUSEHOLD_MEMBER_REMOVE', 'Remove members from the household.'),
       ('HOUSEHOLD_MEMBER_ASSIGN_ROLE', 'Assign household roles to members.'),
       ('HOUSEHOLD_ROLE_VIEW', 'View household roles and their permissions.'),
       ('HOUSEHOLD_ROLE_CREATE', 'Create household roles and configure their permissions.'),
       ('HOUSEHOLD_ROLE_UPDATE', 'Update household roles and their permissions.'),
       ('HOUSEHOLD_ROLE_DELETE', 'Delete household roles.'),
       ('CHORE_CREATE', 'Create chores in the household.'),
       ('CHORE_UPDATE', 'Edit chore details, schedules, and recurrence.'),
       ('CHORE_DELETE', 'Delete chores in the household.'),
       ('CHORE_ASSIGN_MEMBER', 'Assign household members to chores.'),
       ('CHORE_COMPLETE', 'Mark chores assigned to the current member as completed.'),
       ('CHORE_REOPEN', 'Reopen completed chores in the household.'),
       ('CHORE_APPROVE_COMPLETION', 'Approve chore completions in the household.')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

ALTER TABLE chore
    ADD CONSTRAINT fk_chore_household FOREIGN KEY (household_id) REFERENCES household(household_id),
    ADD CONSTRAINT fk_chore_creator_user FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
    ADD CONSTRAINT fk_chore_created_by_member FOREIGN KEY (created_by_household_member_id) REFERENCES household_member(household_member_id),
    ADD CONSTRAINT fk_chore_updated_by_member FOREIGN KEY (updated_by_household_member_id) REFERENCES household_member(household_member_id),
    ADD CONSTRAINT ck_chore_approval_count CHECK (required_approval_count >= 0);

ALTER TABLE chore_schedule
    ADD CONSTRAINT fk_chore_schedule_chore FOREIGN KEY (chore_id) REFERENCES chore(chore_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_chore_schedule_created_by_member FOREIGN KEY (created_by_household_member_id) REFERENCES household_member(household_member_id),
    ADD CONSTRAINT fk_chore_schedule_updated_by_member FOREIGN KEY (updated_by_household_member_id) REFERENCES household_member(household_member_id),
    ADD CONSTRAINT ck_chore_schedule_type CHECK (schedule_type IN ('FIXED', 'AFTER_COMPLETION', 'ON_DEMAND')),
    ADD CONSTRAINT ck_chore_schedule_unit CHECK (recurrence_unit IN ('HOUR', 'DAY', 'WEEK', 'MONTH', 'YEAR')),
    ADD CONSTRAINT ck_chore_schedule_interval CHECK (recurrence_interval > 0),
    ADD CONSTRAINT ck_chore_schedule_recurrence CHECK (
        (schedule_type = 'ON_DEMAND' AND recurrence_unit IS NULL AND starts_at IS NULL)
        OR (schedule_type IN ('FIXED', 'AFTER_COMPLETION') AND recurrence_unit IS NOT NULL)
    ),
    ADD CONSTRAINT ck_chore_schedule_fixed_start CHECK (schedule_type <> 'FIXED' OR starts_at IS NOT NULL),
    ADD CONSTRAINT ck_chore_schedule_start_offset CHECK (
        (starts_at IS NULL AND starts_at_offset_seconds IS NULL)
        OR (starts_at IS NOT NULL AND starts_at_offset_seconds IS NOT NULL
            AND starts_at_offset_seconds BETWEEN -64800 AND 64800)
    );

ALTER TABLE chore_occurrence
    ADD CONSTRAINT fk_chore_occurrence_chore FOREIGN KEY (chore_id) REFERENCES chore(chore_id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_chore_occurrence_created_by_member FOREIGN KEY (created_by_household_member_id) REFERENCES household_member(household_member_id),
    ADD CONSTRAINT fk_chore_occurrence_updated_by_member FOREIGN KEY (updated_by_household_member_id) REFERENCES household_member(household_member_id),
    ADD CONSTRAINT ck_chore_occurrence_approval_count CHECK (required_approval_count >= 0),
    ADD CONSTRAINT ck_chore_occurrence_status CHECK (occurrence_status IN ('PENDING', 'IN_PROGRESS', 'AWAITING_APPROVAL', 'COMPLETED', 'SKIPPED', 'CANCELLED')),
    ADD CONSTRAINT ck_chore_occurrence_deadline CHECK (scheduled_at IS NULL OR due_at IS NULL OR due_at >= scheduled_at);

ALTER TABLE chore_assigned_member
    ADD CONSTRAINT pk_chore_assigned_member PRIMARY KEY (chore_id, household_member_id),
    ADD CONSTRAINT fk_chore_assigned_member_member FOREIGN KEY (household_member_id) REFERENCES household_member(household_member_id),
    DROP CONSTRAINT fk_chore_assigned_member_on_chore,
    ADD CONSTRAINT fk_chore_assigned_member_on_chore FOREIGN KEY (chore_id) REFERENCES chore(chore_id) ON DELETE CASCADE;

ALTER TABLE chore_occurrence_assigned_member
    ADD CONSTRAINT pk_chore_occurrence_assigned_member PRIMARY KEY (chore_occurrence_id, household_member_id),
    ADD CONSTRAINT fk_chore_occurrence_assigned_member_member FOREIGN KEY (household_member_id) REFERENCES household_member(household_member_id),
    DROP CONSTRAINT fk_chore_occurrence_assigned_member_on_chore_occurrence,
    ADD CONSTRAINT fk_chore_occurrence_assigned_member_on_chore_occurrence FOREIGN KEY (chore_occurrence_id) REFERENCES chore_occurrence(chore_occurrence_id) ON DELETE CASCADE;

ALTER TABLE refresh_sessions
    DROP CONSTRAINT fk_refresh_sessions_on_user,
    ADD CONSTRAINT fk_refresh_sessions_on_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE refresh_tokens
    DROP CONSTRAINT fk_refresh_tokens_on_session,
    ADD CONSTRAINT fk_refresh_tokens_on_session FOREIGN KEY (session_id) REFERENCES refresh_sessions(session_id) ON DELETE CASCADE;

CREATE INDEX ix_chore_household ON chore(household_id);
CREATE INDEX ix_chore_occurrence_chore ON chore_occurrence(chore_id);
CREATE INDEX idx_refresh_sessions_user ON refresh_sessions(user_id);
CREATE INDEX idx_refresh_sessions_expiry ON refresh_sessions(expires_at);
CREATE INDEX idx_refresh_tokens_session ON refresh_tokens(session_id);
