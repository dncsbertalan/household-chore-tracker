-- The composite FK keeps the invited role in the invitation's household.
ALTER TABLE household_role
    ADD CONSTRAINT uc_household_role_household UNIQUE (household_id, household_role_id);

CREATE TABLE household_invitation
(
    household_invitation_id UUID PRIMARY KEY,
    household_id            UUID                           NOT NULL REFERENCES household (household_id) ON DELETE CASCADE,
    email                   VARCHAR(255)                   NOT NULL,
    invited_by_user_id      UUID                           NOT NULL REFERENCES users (user_id),
    household_role_id       UUID                           NOT NULL,
    status                  VARCHAR(20)                    NOT NULL,
    expires_at              TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    responded_at            TIMESTAMP(6) WITHOUT TIME ZONE,
    created_at              TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    updated_at              TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    version                 BIGINT                         NOT NULL,
    CONSTRAINT fk_invitation_household_role FOREIGN KEY (household_id, household_role_id)
        REFERENCES household_role (household_id, household_role_id),
    CONSTRAINT ck_invitation_email CHECK (email = lower(btrim(email)) AND length(email) > 0),
    CONSTRAINT ck_invitation_status CHECK (status IN ('PENDING', 'ACCEPTED', 'DECLINED', 'REVOKED', 'EXPIRED')),
    CONSTRAINT ck_invitation_expiry CHECK (expires_at > created_at),
    CONSTRAINT ck_invitation_response CHECK (
        (status = 'PENDING' AND responded_at IS NULL)
            OR (status <> 'PENDING' AND responded_at IS NOT NULL)
        )
);

-- Expired pending rows are closed when a replacement invitation is created.
CREATE UNIQUE INDEX uc_invitation_pending_email ON household_invitation (household_id, email)
    WHERE status = 'PENDING';
CREATE INDEX ix_invitation_inbox ON household_invitation (email, expires_at) WHERE status = 'PENDING';
