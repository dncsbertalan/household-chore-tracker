package hu.dncs.tracker.idempotency.api.web;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Requires a stable UUID Idempotency-Key on an authenticated, synchronous REST mutation.
 * The operation name must stay stable across releases.
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Idempotent {
    String value();
}
