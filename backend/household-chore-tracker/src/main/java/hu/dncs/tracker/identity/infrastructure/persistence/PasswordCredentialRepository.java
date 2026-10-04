package hu.dncs.tracker.identity.infrastructure.persistence;

import hu.dncs.tracker.identity.domain.model.PasswordCredential;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PasswordCredentialRepository extends JpaRepository<PasswordCredential, UUID> {
    @EntityGraph(attributePaths = "user")
    Optional<PasswordCredential> findByUserEmail(String email);
}
