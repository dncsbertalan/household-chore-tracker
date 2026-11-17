CREATE TABLE notification_clock (id INTEGER PRIMARY KEY CHECK (id=1), value BIGINT NOT NULL);
INSERT INTO notification_clock VALUES (1, 0);
CREATE TABLE app_notification (
    notification_id UUID PRIMARY KEY,
    sequence BIGINT NOT NULL UNIQUE,
    recipient_user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    recipient_email VARCHAR(255),
    household_id UUID REFERENCES household(household_id) ON DELETE CASCADE,
    chore_id UUID REFERENCES chore(chore_id) ON DELETE CASCADE,
    invitation_id UUID REFERENCES household_invitation(household_invitation_id) ON DELETE CASCADE,
    kind VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    read_at TIMESTAMPTZ,
    CHECK ((recipient_user_id IS NOT NULL) <> (recipient_email IS NOT NULL))
);
CREATE INDEX ix_notification_user ON app_notification(recipient_user_id, sequence);
CREATE INDEX ix_notification_email ON app_notification(recipient_email, sequence);
CREATE INDEX ix_notification_household ON app_notification(household_id);
CREATE TABLE push_device (
    installation_id UUID PRIMARY KEY,
    account_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    token VARCHAR(512),
    sandbox BOOLEAN NOT NULL,
    binding_version BIGINT NOT NULL CHECK (binding_version >= 0),
    updated_at TIMESTAMPTZ NOT NULL
);
CREATE UNIQUE INDEX uq_push_device_token ON push_device(token) WHERE token IS NOT NULL;
CREATE TABLE notification_delivery (
    notification_id UUID NOT NULL REFERENCES app_notification(notification_id) ON DELETE CASCADE,
    installation_id UUID NOT NULL REFERENCES push_device(installation_id) ON DELETE CASCADE,
    state VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (state IN ('PENDING','SENT','FAILED','CANCELLED')),
    attempts INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL,
    lease_id UUID,
    locked_until TIMESTAMPTZ,
    PRIMARY KEY(notification_id, installation_id)
);
CREATE INDEX ix_delivery_pending ON notification_delivery(next_attempt_at) WHERE state='PENDING';
