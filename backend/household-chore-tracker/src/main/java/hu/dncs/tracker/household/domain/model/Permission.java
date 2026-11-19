package hu.dncs.tracker.household.domain.model;

import jakarta.persistence.*;
import lombok.Getter;

@Entity
@Table(name = "permission")
@Getter
public class Permission {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "permission_id")
    private Long permissionId;

    @Enumerated(EnumType.STRING)
    @Column(name = "name", nullable = false, unique = true, length = 100)
    private HouseholdPermission name;

    @Column(name = "description")
    private String description;

    protected Permission() {
    }
}
