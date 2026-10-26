CREATE TABLE processed_request
(
    account_id            UUID                     NOT NULL,
    request_id            UUID                     NOT NULL,
    operation             VARCHAR(100)             NOT NULL,
    request_hash          VARCHAR(64)              NOT NULL,
    response_status       INTEGER,
    response_content_type TEXT,
    response_location     TEXT,
    response_etag         TEXT,
    response_body         BYTEA,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_processed_request PRIMARY KEY (account_id, request_id),
    CONSTRAINT fk_processed_request_account FOREIGN KEY (account_id) REFERENCES users (user_id) ON DELETE CASCADE,
    CONSTRAINT ck_processed_request_response CHECK (
        (response_status IS NULL AND response_content_type IS NULL AND response_location IS NULL
            AND response_etag IS NULL AND response_body IS NULL)
        OR (response_status IS NOT NULL AND response_status BETWEEN 200 AND 299 AND response_body IS NOT NULL)
    )
);
