package hu.dncs.tracker.idempotency.application;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HouseholdReceiptRedaction {
    private final JdbcTemplate jdbc;

    @Transactional(propagation = Propagation.MANDATORY)
    public void redact(UUID householdId) {
        // Preserve keys and request fingerprints so an old create/accept cannot be executed a second time.
        // Only exact household scope fields are examined; incidental text in another household is ignored.
        jdbc.update("""
            with representations as (
                select account_id, request_id,
                    case when response_content_type like 'application/json%' and octet_length(response_body) > 0
                        then convert_from(response_body, 'UTF8')::jsonb else '{}'::jsonb end as data
                from processed_request where response_status between 200 and 299
            )
            update processed_request r set response_status = 410, response_content_type = 'application/problem+json',
                response_location = null, response_etag = null,
                response_body = convert_to('{"type":"about:blank","title":"Household deleted","status":410,"code":"household_deleted"}', 'UTF8')
            from representations p
            where r.account_id = p.account_id and r.request_id = p.request_id
              and (p.data ->> 'householdId' = ? or p.data #>> '{household,householdId}' = ?
                   or p.data #>> '{management,household,householdId}' = ?)
            """, householdId.toString(), householdId.toString(), householdId.toString());
    }
}
