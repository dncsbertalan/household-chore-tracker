ALTER TABLE household_member
    ADD CONSTRAINT fk_household_member_on_household
        FOREIGN KEY (household_id) REFERENCES household (household_id);
