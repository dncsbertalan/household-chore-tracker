-- Remove client catch-up infrastructure. Applied migrations V1-V4 remain unchanged.
DROP VIEW IF EXISTS sync_entity_state;
DROP TABLE IF EXISTS sync_snapshot_items;
DROP TABLE IF EXISTS sync_snapshots;
DROP TABLE IF EXISTS sync_changes;
DROP TABLE IF EXISTS sync_sequence_state;
-- Membership and role indexes from V4 remain useful for normal resource queries.
-- JPA version columns and explicit HTTP idempotency receipts retain their independent purpose.
