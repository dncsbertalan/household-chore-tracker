-- Deleted household representations are redacted, while keys remain reserved against replay.
ALTER TABLE processed_request DROP CONSTRAINT ck_processed_request_response;
ALTER TABLE processed_request ADD CONSTRAINT ck_processed_request_response CHECK (
    (response_status IS NULL AND response_content_type IS NULL AND response_location IS NULL
        AND response_etag IS NULL AND response_body IS NULL)
    OR (response_status IS NOT NULL AND (response_status BETWEEN 200 AND 299 OR response_status = 410)
        AND response_body IS NOT NULL)
);
