CREATE TABLE chore
(
    chore_id                       UUID                           NOT NULL,
    household_id                   UUID                           NOT NULL,
    title                          VARCHAR(100)                   NOT NULL,
    description                    VARCHAR(500),
    created_by_user_id             UUID                           NOT NULL,
    required_approval_count        INTEGER                        NOT NULL,
    updated_by_household_member_id UUID                           NOT NULL,
    updated_at                     TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    created_by_household_member_id UUID                           NOT NULL,
    created_at                     TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    version                        BIGINT                         NOT NULL,
    CONSTRAINT pk_chore PRIMARY KEY (chore_id)
);

CREATE TABLE chore_assigned_member
(
    chore_id            UUID NOT NULL,
    household_member_id UUID NOT NULL
);

CREATE TABLE chore_occurrence
(
    chore_occurrence_id            UUID                           NOT NULL,
    chore_id                       UUID                           NOT NULL,
    title                          VARCHAR(100)                   NOT NULL,
    description                    VARCHAR(500),
    required_approval_count        INTEGER                        NOT NULL,
    scheduled_at                   TIMESTAMP(6) WITHOUT TIME ZONE,
    due_at                         TIMESTAMP(6) WITHOUT TIME ZONE,
    occurrence_status              VARCHAR(30)                    NOT NULL,
    updated_by_household_member_id UUID                           NOT NULL,
    updated_at                     TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    created_by_household_member_id UUID                           NOT NULL,
    created_at                     TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    version                        BIGINT                         NOT NULL,
    CONSTRAINT pk_chore_occurrence PRIMARY KEY (chore_occurrence_id)
);

CREATE TABLE chore_occurrence_assigned_member
(
    chore_occurrence_id UUID NOT NULL,
    household_member_id UUID NOT NULL
);

CREATE TABLE chore_schedule
(
    chore_schedule_id              UUID                           NOT NULL,
    chore_id                       UUID                           NOT NULL,
    schedule_type                  VARCHAR(30)                    NOT NULL,
    recurrence_unit                VARCHAR(10),
    recurrence_interval            INTEGER                        NOT NULL,
    starts_at                      TIMESTAMP(6) WITHOUT TIME ZONE,
    starts_at_offset_seconds       INTEGER,
    time_zone_identifier           VARCHAR(100)                   NOT NULL,
    updated_by_household_member_id UUID                           NOT NULL,
    updated_at                     TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    created_by_household_member_id UUID                           NOT NULL,
    created_at                     TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    version                        BIGINT                         NOT NULL,
    CONSTRAINT pk_chore_schedule PRIMARY KEY (chore_schedule_id)
);

CREATE TABLE household
(
    household_id       UUID                           NOT NULL,
    name               VARCHAR(100)                   NOT NULL,
    description        VARCHAR(500),
    created_by_user_id UUID                           NOT NULL,
    updated_at         TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    created_at         TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    version            BIGINT,
    CONSTRAINT pk_household PRIMARY KEY (household_id)
);

CREATE TABLE household_member
(
    household_member_id UUID                           NOT NULL,
    household_id        UUID                           NOT NULL,
    user_id             UUID                           NOT NULL,
    nickname            VARCHAR(100),
    household_role_id   UUID                           NOT NULL,
    joined_at           TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    updated_at          TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    created_at          TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    version             BIGINT,
    CONSTRAINT pk_household_member PRIMARY KEY (household_member_id)
);

CREATE TABLE household_role
(
    household_role_id UUID                           NOT NULL,
    household_id      UUID                           NOT NULL,
    name              VARCHAR(50)                    NOT NULL,
    is_system_role    BOOLEAN                        NOT NULL,
    updated_at        TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    created_at        TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    version           BIGINT                         NOT NULL,
    CONSTRAINT pk_household_role PRIMARY KEY (household_role_id)
);

CREATE TABLE household_role_permission
(
    household_role_id UUID   NOT NULL,
    permission_id     BIGINT NOT NULL,
    CONSTRAINT pk_household_role_permission PRIMARY KEY (household_role_id, permission_id)
);

CREATE TABLE password_credentials
(
    user_id       UUID         NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    CONSTRAINT pk_password_credentials PRIMARY KEY (user_id)
);

CREATE TABLE permission
(
    permission_id BIGINT GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    name          VARCHAR(100)                            NOT NULL,
    description   VARCHAR(255),
    CONSTRAINT pk_permission PRIMARY KEY (permission_id)
);

CREATE TABLE processed_request
(
    operation             VARCHAR(100)                   NOT NULL,
    request_hash          VARCHAR(64)                    NOT NULL,
    response_status       INTEGER,
    response_content_type VARCHAR(255),
    response_location     VARCHAR(255),
    response_etag         VARCHAR(255),
    response_body         BYTEA,
    created_at            TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    account_id            UUID                           NOT NULL,
    request_id            UUID                           NOT NULL,
    CONSTRAINT pk_processed_request PRIMARY KEY (account_id, request_id)
);

CREATE TABLE refresh_sessions
(
    session_id UUID                           NOT NULL,
    user_id    UUID                           NOT NULL,
    expires_at TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    revoked_at TIMESTAMP(6) WITHOUT TIME ZONE,
    CONSTRAINT pk_refresh_sessions PRIMARY KEY (session_id)
);

CREATE TABLE refresh_tokens
(
    token_hash VARCHAR(64) NOT NULL,
    session_id UUID        NOT NULL,
    used_at    TIMESTAMP(6) WITHOUT TIME ZONE,
    CONSTRAINT pk_refresh_tokens PRIMARY KEY (token_hash)
);

CREATE TABLE revchanges
(
    rev        BIGINT NOT NULL,
    entityname VARCHAR(255)
);

CREATE TABLE revinfo
(
    rev      BIGINT NOT NULL,
    revtstmp BIGINT,
    CONSTRAINT pk_revinfo PRIMARY KEY (rev)
);

CREATE TABLE users
(
    user_id    UUID                           NOT NULL,
    email      VARCHAR(255)                   NOT NULL,
    first_name VARCHAR(100)                   NOT NULL,
    last_name  VARCHAR(100)                   NOT NULL,
    updated_at TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    created_at TIMESTAMP(6) WITHOUT TIME ZONE NOT NULL,
    CONSTRAINT pk_users PRIMARY KEY (user_id)
);

ALTER TABLE household_member
    ADD CONSTRAINT uc_22143b80a90a9265499540808 UNIQUE (household_id, user_id);

ALTER TABLE chore_schedule
    ADD CONSTRAINT uc_chore_schedule_chore UNIQUE (chore_id);

ALTER TABLE permission
    ADD CONSTRAINT uc_permission_name UNIQUE (name);

ALTER TABLE users
    ADD CONSTRAINT uc_users_email UNIQUE (email);

ALTER TABLE household_member
    ADD CONSTRAINT FK_HOUSEHOLD_MEMBER_ON_HOUSEHOLD FOREIGN KEY (household_id) REFERENCES household (household_id);

ALTER TABLE household_member
    ADD CONSTRAINT FK_HOUSEHOLD_MEMBER_ON_HOUSEHOLD_ROLE FOREIGN KEY (household_role_id) REFERENCES household_role (household_role_id);

ALTER TABLE password_credentials
    ADD CONSTRAINT FK_PASSWORD_CREDENTIALS_ON_USER FOREIGN KEY (user_id) REFERENCES users (user_id);

ALTER TABLE refresh_sessions
    ADD CONSTRAINT FK_REFRESH_SESSIONS_ON_USER FOREIGN KEY (user_id) REFERENCES users (user_id);

ALTER TABLE refresh_tokens
    ADD CONSTRAINT FK_REFRESH_TOKENS_ON_SESSION FOREIGN KEY (session_id) REFERENCES refresh_sessions (session_id);

ALTER TABLE chore_assigned_member
    ADD CONSTRAINT fk_chore_assigned_member_on_chore FOREIGN KEY (chore_id) REFERENCES chore (chore_id);

ALTER TABLE chore_occurrence_assigned_member
    ADD CONSTRAINT fk_chore_occurrence_assigned_member_on_chore_occurrence FOREIGN KEY (chore_occurrence_id) REFERENCES chore_occurrence (chore_occurrence_id);

ALTER TABLE household_role_permission
    ADD CONSTRAINT fk_hourolper_on_household_role FOREIGN KEY (household_role_id) REFERENCES household_role (household_role_id);

ALTER TABLE household_role_permission
    ADD CONSTRAINT fk_hourolper_on_permission FOREIGN KEY (permission_id) REFERENCES permission (permission_id);

ALTER TABLE revchanges
    ADD CONSTRAINT fk_revchanges_on_default_tracking_modified_entities_changelog FOREIGN KEY (rev) REFERENCES revinfo (rev);
