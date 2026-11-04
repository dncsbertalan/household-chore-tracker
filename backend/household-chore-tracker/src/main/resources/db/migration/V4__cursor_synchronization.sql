-- A transactional row counter, deliberately NOT a PostgreSQL sequence.
CREATE TABLE sync_sequence_state (
    id SMALLINT PRIMARY KEY CHECK (id = 1),
    last_sequence BIGINT NOT NULL CHECK (last_sequence >= 0),
    retention_floor BIGINT NOT NULL DEFAULT 0 CHECK (retention_floor >= 0 AND retention_floor <= last_sequence)
);
INSERT INTO sync_sequence_state(id, last_sequence) VALUES (1, 0);
CREATE TABLE sync_changes (
    sequence BIGINT PRIMARY KEY,
    entity_type VARCHAR(40) NOT NULL,
    entity_id UUID NOT NULL,
    household_id UUID NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('UPSERT', 'DELETE')),
    entity_version BIGINT NOT NULL,
    schema_version INTEGER NOT NULL DEFAULT 1,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK ((operation = 'UPSERT') = (payload IS NOT NULL))
);
-- Membership-filtered keyset queries, in addition to the global primary key.
CREATE INDEX ix_sync_changes_household_sequence ON sync_changes(household_id, sequence);
CREATE INDEX ix_household_member_user_household ON household_member(user_id, household_id);
CREATE INDEX ix_household_role_household ON household_role(household_id);

-- Immutable server-side snapshots survive pagination without keeping transactions open.
-- Each account has at most one snapshot; abandoned snapshots are replaced on next bootstrap.
CREATE TABLE sync_snapshots (
    account_id UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    snapshot_id UUID NOT NULL UNIQUE,
    scope VARCHAR(64) NOT NULL,
    high_water BIGINT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '1 day')
);
CREATE TABLE sync_snapshot_items (
    snapshot_id UUID NOT NULL REFERENCES sync_snapshots(snapshot_id) ON DELETE CASCADE,
    position BIGINT NOT NULL,
    entity_type VARCHAR(40) NOT NULL,
    entity_id UUID NOT NULL,
    household_id UUID NOT NULL,
    entity_version BIGINT NOT NULL,
    payload JSONB NOT NULL,
    PRIMARY KEY (snapshot_id, position)
);

-- Allowlisted sync projections also bootstrap data created before this migration.
-- Dates in the existing schema are UTC timestamps without time zone.
CREATE VIEW sync_entity_state AS
SELECT 'HOUSEHOLD'::varchar AS entity_type, t.household_id AS entity_id, t.household_id AS household_id,
       COALESCE(t.version,0) AS entity_version, 0 AS dependency_order,
       jsonb_build_object('householdId', t.household_id,
           'name', t.name,
           'description', t.description,
           'createdByUserId', t.created_by_user_id,
           'version', COALESCE(t.version,0)) AS payload
FROM household t 
UNION ALL
SELECT 'HOUSEHOLD_ROLE'::varchar AS entity_type, t.household_role_id AS entity_id, t.household_id AS household_id,
       COALESCE(t.version,0) AS entity_version, 1 AS dependency_order,
       jsonb_build_object('householdRoleId', t.household_role_id,
           'householdId', t.household_id,
           'name', t.name,
           'isSystemRole', t.is_system_role,
           'version', t.version,
           'permissions', COALESCE((SELECT jsonb_agg(p.name ORDER BY p.name) FROM household_role_permission rp JOIN permission p USING(permission_id) WHERE rp.household_role_id=t.household_role_id),'[]'::jsonb)) AS payload
FROM household_role t 
UNION ALL
SELECT 'HOUSEHOLD_MEMBER'::varchar AS entity_type, t.household_member_id AS entity_id, t.household_id AS household_id,
       COALESCE(t.version,0) AS entity_version, 2 AS dependency_order,
       jsonb_build_object('householdMemberId', t.household_member_id,
           'householdId', t.household_id,
           'userId', t.user_id,
           'nickname', t.nickname,
           'householdRoleId', t.household_role_id,
           'joinedAt', t.joined_at AT TIME ZONE 'UTC',
           'version', COALESCE(t.version,0)) AS payload
FROM household_member t 
UNION ALL
SELECT 'CHORE'::varchar AS entity_type, t.chore_id AS entity_id, t.household_id AS household_id,
       COALESCE(t.version,0) AS entity_version, 3 AS dependency_order,
       jsonb_build_object('choreId', t.chore_id,
           'householdId', t.household_id,
           'createdByUserId', t.created_by_user_id,
           'title', t.title,
           'description', t.description,
           'requiredApprovalCount', t.required_approval_count,
           'createdAt', t.created_at AT TIME ZONE 'UTC',
           'updatedAt', t.updated_at AT TIME ZONE 'UTC',
           'createdByHouseholdMemberId', t.created_by_household_member_id,
           'updatedByHouseholdMemberId', t.updated_by_household_member_id,
           'version', t.version,
           'assignedMemberIds', COALESCE((SELECT jsonb_agg(a.household_member_id ORDER BY a.household_member_id) FROM chore_assigned_member a WHERE a.chore_id=t.chore_id),'[]'::jsonb)) AS payload
FROM chore t 
UNION ALL
SELECT 'CHORE_SCHEDULE'::varchar AS entity_type, t.chore_schedule_id AS entity_id, c.household_id AS household_id,
       COALESCE(t.version,0) AS entity_version, 4 AS dependency_order,
       jsonb_build_object('choreScheduleId', t.chore_schedule_id,
           'choreId', t.chore_id,
           'householdId', c.household_id,
           'scheduleType', t.schedule_type,
           'recurrenceUnit', t.recurrence_unit,
           'recurrenceInterval', t.recurrence_interval,
           'startsAt', (t.starts_at - make_interval(secs => t.starts_at_offset_seconds)) AT TIME ZONE 'UTC',
           'timeZoneIdentifier', t.time_zone_identifier,
           'version', t.version,
           'createdAt', t.created_at AT TIME ZONE 'UTC',
           'updatedAt', t.updated_at AT TIME ZONE 'UTC',
           'createdByHouseholdMemberId', t.created_by_household_member_id,
           'updatedByHouseholdMemberId', t.updated_by_household_member_id) AS payload
FROM chore_schedule t JOIN chore c ON c.chore_id=t.chore_id
UNION ALL
SELECT 'CHORE_OCCURRENCE'::varchar AS entity_type, t.chore_occurrence_id AS entity_id, c.household_id AS household_id,
       COALESCE(t.version,0) AS entity_version, 5 AS dependency_order,
       jsonb_build_object('choreOccurrenceId', t.chore_occurrence_id,
           'choreId', t.chore_id,
           'householdId', c.household_id,
           'title', t.title,
           'description', t.description,
           'requiredApprovalCount', t.required_approval_count,
           'createdAt', t.created_at AT TIME ZONE 'UTC',
           'updatedAt', t.updated_at AT TIME ZONE 'UTC',
           'createdByHouseholdMemberId', t.created_by_household_member_id,
           'updatedByHouseholdMemberId', t.updated_by_household_member_id,
           'version', t.version,
           'assignedMemberIds', COALESCE((SELECT jsonb_agg(a.household_member_id ORDER BY a.household_member_id) FROM chore_occurrence_assigned_member a WHERE a.chore_occurrence_id=t.chore_occurrence_id),'[]'::jsonb),
           'scheduledAt', t.scheduled_at AT TIME ZONE 'UTC',
           'dueAt', t.due_at AT TIME ZONE 'UTC',
           'occurrenceStatus', t.occurrence_status) AS payload
FROM chore_occurrence t JOIN chore c ON c.chore_id=t.chore_id;
