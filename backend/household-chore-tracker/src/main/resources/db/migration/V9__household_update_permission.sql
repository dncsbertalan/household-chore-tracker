-- Grant explicitly through role management; existing roles keep their current permissions.
INSERT INTO permission(name, description)
VALUES ('HOUSEHOLD_UPDATE', 'Edit the household name and description.')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;
