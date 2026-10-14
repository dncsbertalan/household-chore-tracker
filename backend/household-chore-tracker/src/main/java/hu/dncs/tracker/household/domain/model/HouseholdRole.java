package hu.dncs.tracker.household.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "household_role")
@Getter
public class HouseholdRole {

    @Id
    @Column(name = "household_role_id")
    private UUID householdRoleId;

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    @Column(name = "name", nullable = false, length = 50)
    private String name;

    @Column(name = "is_system_role", nullable = false)
    private Boolean isSystemRole;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "household_role_permission",
            joinColumns = @JoinColumn(name = "household_role_id"),
            inverseJoinColumns = @JoinColumn(name = "permission_id")
    )
    private final Set<Permission> permissions = new HashSet<>();

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    protected HouseholdRole() {
    }

    public HouseholdRole(UUID householdRoleId, UUID householdId, String name, Boolean isSystemRole) {
        this.householdRoleId = Objects.requireNonNull(householdRoleId);
        this.householdId = Objects.requireNonNull(householdId);
        this.name = Objects.requireNonNull(name);
        this.isSystemRole = isSystemRole;
    }

    public Boolean isIsSystemRole() {
        return isSystemRole;
    }
}
