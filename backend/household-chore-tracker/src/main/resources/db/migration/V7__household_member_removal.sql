-- Preserve membership IDs referenced by chore history while revoking household access.
ALTER TABLE household_member ADD COLUMN removed_at TIMESTAMPTZ;
