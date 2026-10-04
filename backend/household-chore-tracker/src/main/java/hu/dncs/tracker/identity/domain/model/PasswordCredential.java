package hu.dncs.tracker.identity.domain.model;

import jakarta.persistence.*;
import lombok.Getter;

import java.util.UUID;

@Entity
@Table(name = "password_credentials")
@Getter
public class PasswordCredential {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @MapsId
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    protected PasswordCredential() {
    }

    public PasswordCredential(User user, String passwordHash) {
        this.user = user;
        this.passwordHash = passwordHash;
    }
}
