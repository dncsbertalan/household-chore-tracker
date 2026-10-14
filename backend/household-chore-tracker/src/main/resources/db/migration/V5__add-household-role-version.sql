ALTER TABLE household_role
    ADD COLUMN version BIGINT NOT NULL DEFAULT 0;

-- Hibernate initializes the version for new roles; the default is only for backfilling existing rows.
ALTER TABLE household_role
    ALTER COLUMN version DROP DEFAULT;
