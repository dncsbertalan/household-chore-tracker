package hu.dncs.tracker.identity.infrastructure.persistence;

import hu.dncs.tracker.identity.domain.model.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, String> {
    @Query("select token.session.id from RefreshToken token where token.tokenHash = :hash")
    Optional<UUID> findSessionIdByTokenHash(String hash);
}
