CREATE TABLE processed_command
(
    account_id        UUID                     NOT NULL,
    command_id        UUID                     NOT NULL,
    command_type      VARCHAR(100)             NOT NULL,
    request_hash      CHAR(64)                 NOT NULL,
    response_status   INTEGER,
    response_location TEXT,
    response_body     TEXT,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_processed_command PRIMARY KEY (account_id, command_id),
    CONSTRAINT fk_processed_command_on_account FOREIGN KEY (account_id) REFERENCES users (user_id) ON DELETE CASCADE,
    CONSTRAINT ck_processed_command_response CHECK (
        (response_status IS NULL AND response_location IS NULL AND response_body IS NULL)
        OR (response_status IS NOT NULL AND response_status BETWEEN 200 AND 299 AND response_body IS NOT NULL)
    )
);
