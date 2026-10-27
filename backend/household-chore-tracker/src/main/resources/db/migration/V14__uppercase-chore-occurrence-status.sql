UPDATE chore_occurrence
SET occurrence_status = CASE occurrence_status
    WHEN 'inProgress' THEN 'IN_PROGRESS'
    WHEN 'awaitingApproval' THEN 'AWAITING_APPROVAL'
    ELSE UPPER(occurrence_status)
END;

ALTER TABLE chore_occurrence
    ADD CONSTRAINT chore_occurrence_status_check
    CHECK (occurrence_status IN ('PENDING', 'IN_PROGRESS', 'AWAITING_APPROVAL', 'COMPLETED', 'SKIPPED', 'CANCELLED'));
