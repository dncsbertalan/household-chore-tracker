package hu.dncs.tracker.identity.infrastructure.persistence;

import hu.dncs.tracker.identity.domain.model.RefreshSession;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface RefreshSessionRepository extends JpaRepository<RefreshSession, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select session from RefreshSession session where session.id = :id")
    Optional<RefreshSession> findByIdForUpdate(UUID id);
}
