ALTER TABLE household
    ADD owner_user_id UUID;

UPDATE household
SET owner_user_id = household.created_by_user_id;

ALTER TABLE household
    ALTER COLUMN owner_user_id SET NOT NULL;

ALTER TABLE household
    ADD CONSTRAINT FK_HOUSEHOLD_ON_USERS FOREIGN KEY (owner_user_id) REFERENCES users (user_id);
