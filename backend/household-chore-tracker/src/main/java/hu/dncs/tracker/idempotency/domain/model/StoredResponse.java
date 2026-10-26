package hu.dncs.tracker.idempotency.domain.model;

/** Only representation headers are replayed; credentials and cookies are never stored. */
public record StoredResponse(int status, String contentType, String location, String etag, byte[] body) {
    public boolean successful() {
        return status >= 200 && status < 300;
    }
}
