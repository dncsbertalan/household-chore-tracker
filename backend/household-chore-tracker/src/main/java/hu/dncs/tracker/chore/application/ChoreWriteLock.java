package hu.dncs.tracker.chore.application;

import hu.dncs.tracker.chore.application.exception.ChoreNotFoundException;
import hu.dncs.tracker.chore.domain.model.Chore;
import hu.dncs.tracker.chore.infrastructure.persistence.ChoreRepository;
import hu.dncs.tracker.household.infrastructure.persistence.HouseholdRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.util.UUID;

/** Lock household before chore, without caching a stale entity while waiting for removal or revocation. */
@Component
@RequiredArgsConstructor
public class ChoreWriteLock {
    private final ChoreRepository chores;
    private final HouseholdRepository households;

    public void household(UUID id) { households.findForUpdate(id).orElseThrow(ChoreNotFoundException::new); }

    public Chore chore(UUID id) {
        household(chores.findHouseholdId(id).orElseThrow(ChoreNotFoundException::new));
        return chores.findForUpdate(id).orElseThrow(ChoreNotFoundException::new);
    }
}
