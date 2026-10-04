CREATE TABLE refresh_sessions
(
    session_id UUID PRIMARY KEY,
    user_id    UUID                        NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    expires_at TIMESTAMP(6) WITH TIME ZONE NOT NULL,
    revoked_at TIMESTAMP(6) WITH TIME ZONE
);

CREATE INDEX idx_refresh_sessions_user ON refresh_sessions (user_id);
CREATE INDEX idx_refresh_sessions_expiry ON refresh_sessions (expires_at);

CREATE TABLE refresh_tokens
(
    token_hash VARCHAR(64) PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES refresh_sessions (session_id) ON DELETE CASCADE,
    used_at    TIMESTAMP(6) WITH TIME ZONE
);

CREATE INDEX idx_refresh_tokens_session ON refresh_tokens (session_id);
