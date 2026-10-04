package hu.dncs.tracker.identity.domain.model;

import jakarta.persistence.*;
import lombok.Getter;

import java.time.Instant;

@Entity
@Table(name = "refresh_tokens")
@Getter
public class RefreshToken {
    @Id
    @Column(name = "token_hash", length = 64)
    private String tokenHash;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "session_id", nullable = false)
    private RefreshSession session;

    @Column(name = "used_at")
    private Instant usedAt;

    protected RefreshToken() {
    }

    public RefreshToken(String tokenHash, RefreshSession session) {
        this.tokenHash = tokenHash;
        this.session = session;
    }

    public void consume(Instant now) {
        if (usedAt != null) {
            throw new IllegalStateException("Refresh token has already been used.");
        }
        this.usedAt = now;
    }
}
