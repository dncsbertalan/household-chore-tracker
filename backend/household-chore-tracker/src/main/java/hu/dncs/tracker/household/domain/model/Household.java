package hu.dncs.tracker.household.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "household")
@Getter
public class Household {
    @Id
    @Column(name = "household_id")
    private UUID householdId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "created_by_user_id", nullable = false)
    private UUID createdByUserId;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Version
    private Long version;

    protected Household() {
    }

    public Household(UUID householdId, String name, String description, UUID createdByUserId) {
        this.householdId = Objects.requireNonNull(householdId);
        this.name = validateName(name);
        this.description = validateDescription(description);
        this.createdByUserId = Objects.requireNonNull(createdByUserId);
    }

    private static String validateName(String name) {
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Household name cannot be empty");
        }

        var normalized = name.trim();

        if (normalized.length() > 100) {
            throw new IllegalArgumentException("Household name is too long");
        }

        return normalized;
    }

    private static String validateDescription(String description) {
        if (description != null && description.length() > 500) {
            throw new IllegalArgumentException("Household description is too long");
        }
        return description;
    }

    public void rename(String newName) {
        this.name = validateName(newName);
        this.updatedAt = Instant.now();
    }

    public void updateDescription(String description) {
        this.description = validateDescription(description);
        this.updatedAt = Instant.now();
    }
}
