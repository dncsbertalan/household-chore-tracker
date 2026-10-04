CREATE TABLE password_credentials
(
    user_id       UUID         NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    CONSTRAINT pk_password_credentials PRIMARY KEY (user_id)
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

ALTER TABLE users
    ADD CONSTRAINT uc_users_email UNIQUE (email);

ALTER TABLE password_credentials
    ADD CONSTRAINT FK_PASSWORD_CREDENTIALS_ON_USER FOREIGN KEY (user_id) REFERENCES users (user_id);