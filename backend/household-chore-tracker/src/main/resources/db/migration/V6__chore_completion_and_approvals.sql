CREATE TABLE chore_completion (
    chore_completion_id UUID PRIMARY KEY,
    chore_occurrence_id UUID NOT NULL REFERENCES chore_occurrence(chore_occurrence_id) ON DELETE CASCADE,
    completed_by_household_member_id UUID NOT NULL REFERENCES household_member(household_member_id),
    submitted_at TIMESTAMPTZ NOT NULL,
    required_approval_count INTEGER NOT NULL CHECK (required_approval_count >= 0),
    status VARCHAR(30) NOT NULL CHECK (status IN ('AWAITING_APPROVAL', 'APPROVED', 'REJECTED')),
    resolved_at TIMESTAMPTZ,
    version BIGINT NOT NULL,
    CONSTRAINT ck_chore_completion_resolution CHECK ((status = 'AWAITING_APPROVAL') = (resolved_at IS NULL))
);
CREATE INDEX ix_chore_completion_occurrence ON chore_completion(chore_occurrence_id);
CREATE UNIQUE INDEX uq_chore_completion_pending ON chore_completion(chore_occurrence_id) WHERE status = 'AWAITING_APPROVAL';
CREATE TABLE chore_approval (
    chore_approval_id UUID PRIMARY KEY,
    chore_completion_id UUID NOT NULL REFERENCES chore_completion(chore_completion_id) ON DELETE CASCADE,
    reviewed_by_household_member_id UUID NOT NULL REFERENCES household_member(household_member_id),
    decision VARCHAR(20) NOT NULL CHECK (decision IN ('APPROVED', 'REJECTED')),
    reviewed_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT uq_chore_approval_reviewer UNIQUE (chore_completion_id, reviewed_by_household_member_id)
);
ALTER TABLE chore_occurrence ADD COLUMN generated_from_occurrence_id UUID
    REFERENCES chore_occurrence(chore_occurrence_id),
    ADD CONSTRAINT uq_chore_occurrence_successor UNIQUE (generated_from_occurrence_id);
INSERT INTO permission(name, description) VALUES
    ('CHORE_SELF_APPROVE_COMPLETION', 'Approve own chore completions; also requires CHORE_APPROVE_COMPLETION.')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;
