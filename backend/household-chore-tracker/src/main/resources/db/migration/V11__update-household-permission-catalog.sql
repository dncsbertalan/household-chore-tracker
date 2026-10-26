-- Remove obsolete grants before deleting the referenced catalog entries.
DELETE FROM household_role_permission
WHERE permission_id IN (
    SELECT permission_id
    FROM permission
    WHERE name IN ('HOUSEHOLD_VIEW', 'HOUSEHOLD_UPDATE')
);

DELETE FROM permission
WHERE name IN ('HOUSEHOLD_VIEW', 'HOUSEHOLD_UPDATE');

-- New permissions are available for role configuration without granting them automatically.
INSERT INTO permission (name, description)
VALUES ('CHORE_UPDATE', 'Edit chore details, schedules, and recurrence.'),
       ('CHORE_DELETE', 'Delete chores in the household.'),
       ('CHORE_ASSIGN_MEMBER', 'Assign household members to chores.'),
       ('CHORE_COMPLETE', 'Mark chores assigned to the current member as completed.'),
       ('CHORE_REOPEN', 'Reopen completed chores in the household.'),
       ('CHORE_APPROVE_COMPLETION', 'Approve chore completions in the household.');
