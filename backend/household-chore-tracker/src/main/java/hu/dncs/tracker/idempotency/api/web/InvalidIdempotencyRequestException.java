package hu.dncs.tracker.idempotency.api.web;

class InvalidIdempotencyRequestException extends RuntimeException {
    InvalidIdempotencyRequestException(String message) {
        super(message);
    }
}
