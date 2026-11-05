package hu.dncs.tracker.household.application;

import hu.dncs.tracker.household.application.command.SaveHouseholdRoleCommand;
import hu.dncs.tracker.household.application.exception.HouseholdRoleManagementException;
import hu.dncs.tracker.household.application.model.HouseholdRoleManagement;
import hu.dncs.tracker.household.application.model.HouseholdMemberRemoval;
import hu.dncs.tracker.chore.application.ChoreMemberRemovalService;
import java.time.Clock;
import hu.dncs.tracker.household.application.usecase.GetHouseholdsUseCase;
import hu.dncs.tracker.household.domain.model.*;
import hu.dncs.tracker.household.infrastructure.persistence.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import static hu.dncs.tracker.household.application.exception.HouseholdRoleManagementException.Reason.*;
import static hu.dncs.tracker.household.domain.model.HouseholdPermission.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HouseholdRoleManagementService {
    private final HouseholdRepository households;
    private final HouseholdRoleRepository roles;
    private final HouseholdMemberRepository members;
    private final HouseholdInvitationRepository invitations;
    private final PermissionRepository permissions;
    private final HouseholdAuthorizationService authorization;
    private final HouseholdRolePolicy policy;
    private final GetHouseholdsUseCase getHouseholds;
    private final ChoreMemberRemovalService choreMemberRemoval;
    private final Clock clock;

    public HouseholdRoleManagement get(UUID householdId, UUID userId) {
        var actor = member(householdId, userId);
        if (!policy.actions(actor).canView()) throw new AccessDeniedException("Role visibility is required.");
        return result(householdId, userId);
    }

    @Transactional
    public HouseholdRoleManagement create(UUID householdId, SaveHouseholdRoleCommand command, UUID userId) {
        lock(householdId);
        authorization.requirePermission(householdId, userId, HOUSEHOLD_ROLE_CREATE);
        var name = validateName(householdId, null, command.name());
        var grants = resolvePermissions(command.permissions());
        var role = new HouseholdRole(UUID.randomUUID(), householdId, name, false);
        role.getPermissions().addAll(grants);
        roles.saveAndFlush(role);
        return result(householdId, userId);
    }

    @Transactional
    public HouseholdRoleManagement update(UUID householdId, UUID roleId, SaveHouseholdRoleCommand command, UUID userId) {
        lock(householdId);
        authorization.requirePermission(householdId, userId, HOUSEHOLD_ROLE_UPDATE);
        var role = role(householdId, roleId);
        requireMutable(role);
        requireVersion(role.getVersion(), command.version());
        var name = validateName(householdId, roleId, command.name());
        var grants = resolvePermissions(command.permissions());
        role.update(name, grants);
        requireManager(householdId);
        roles.flush();
        return result(householdId, userId);
    }

    @Transactional
    public HouseholdRoleManagement delete(UUID householdId, UUID roleId, Long version, UUID userId) {
        lock(householdId);
        authorization.requirePermission(householdId, userId, HOUSEHOLD_ROLE_DELETE);
        var role = role(householdId, roleId);
        requireMutable(role);
        requireVersion(role.getVersion(), version);
        if (members.existsByHouseholdRole_HouseholdRoleId(roleId) || invitations.existsByHouseholdRole_HouseholdRoleId(roleId)) {
            throw error(IN_USE, "This role is assigned to members or referenced by invitations.");
        }
        roles.delete(role);
        roles.flush();
        return result(householdId, userId);
    }

    @Transactional
    public HouseholdRoleManagement assign(UUID householdId, UUID memberId, UUID roleId, Long memberVersion, Long roleVersion, UUID userId) {
        lock(householdId);
        authorization.requirePermission(householdId, userId, HOUSEHOLD_MEMBER_ASSIGN_ROLE);
        var target = members.findAllByHousehold_HouseholdId(householdId).stream()
                .filter(m -> m.getHouseholdMemberId().equals(memberId)).findFirst()
                .orElseThrow(() -> error(NOT_FOUND, "Household member not found."));
        var role = role(householdId, roleId);
        requireVersion(target.getVersion(), memberVersion);
        requireVersion(role.getVersion(), roleVersion);
        boolean hadManager = hasManager(householdId);
        target.assignRole(role);
        if (hadManager) requireManager(householdId);
        members.flush();
        return result(householdId, userId);
    }

    @Transactional
    public HouseholdMemberRemoval removeMember(UUID householdId, UUID memberId, Long version, UUID userId) {
        lock(householdId);
        authorization.requirePermission(householdId, userId, HOUSEHOLD_MEMBER_REMOVE);
        var actor = member(householdId, userId);
        var target = members.findAllByHousehold_HouseholdId(householdId).stream()
                .filter(m -> m.getHouseholdMemberId().equals(memberId)).findFirst()
                .orElseThrow(() -> error(NOT_FOUND, "Household member not found."));
        requireVersion(target.getVersion(), version);
        target.remove(clock.instant());
        // The query flushes the removal and counts only active members, under the household lock.
        requireManager(householdId);
        choreMemberRemoval.removeAssignments(householdId, memberId, actor.getHouseholdMemberId());
        members.flush();
        return new HouseholdMemberRemoval(householdId, memberId,
                target.getUserId().equals(userId) ? null : result(householdId, userId));
    }

    private HouseholdRoleManagement result(UUID householdId, UUID userId) {
        var actions = policy.actions(member(householdId, userId));
        var catalog = actions.canView() ? permissions.findAll().stream().sorted(Comparator.comparing(Permission::getName)).toList() : List.<Permission>of();
        return new HouseholdRoleManagement(getHouseholds.one(householdId, userId), catalog, actions);
    }
    private void lock(UUID id) {
        if (households.findForUpdate(id).isEmpty()) throw error(NOT_FOUND, "Household not found.");
    }
    private HouseholdMember member(UUID householdId, UUID userId) {
        return members.findByHousehold_HouseholdIdAndUserId(householdId, userId)
                .orElseThrow(() -> new AccessDeniedException("Household membership is required."));
    }
    private HouseholdRole role(UUID householdId, UUID roleId) {
        return roles.findAllByHouseholdIdOrderByCreatedAtAscHouseholdRoleIdAsc(householdId).stream()
                .filter(r -> r.getHouseholdRoleId().equals(roleId)).findFirst()
                .orElseThrow(() -> error(NOT_FOUND, "Role not found in this household."));
    }
    private String validateName(UUID householdId, UUID roleId, String name) {
        var normalized = HouseholdRole.normalizedName(name);
        if (normalized.isEmpty() || normalized.length() > 50) throw error(INVALID, "Role names must contain 1–50 characters.");
        if (roles.findAllByHouseholdIdOrderByCreatedAtAscHouseholdRoleIdAsc(householdId).stream()
                .anyMatch(r -> !r.getHouseholdRoleId().equals(roleId) && HouseholdRole.normalizedName(r.getName()).equalsIgnoreCase(normalized))) {
            throw error(DUPLICATE_NAME, "A role with this name already exists in this household.");
        }
        return normalized;
    }
    // Role create/update are delegation privileges and may grant any catalog permission.
    private List<Permission> resolvePermissions(List<HouseholdPermission> names) {
        if (names == null || names.stream().anyMatch(Objects::isNull) || new HashSet<>(names).size() != names.size()) {
            throw error(INVALID, "Supply a unique list of known permissions.");
        }
        return names.stream().map(name -> permissions.findByName(name)
                .orElseThrow(() -> error(INVALID, "Unknown permission."))).toList();
    }
    private boolean hasManager(UUID householdId) {
        return members.findAllByHousehold_HouseholdId(householdId).stream()
                .anyMatch(m -> m.getHouseholdRole().getHouseholdId().equals(householdId)
                        && m.getHouseholdRole().getPermissions().stream().anyMatch(p -> p.getName().equals(HOUSEHOLD_ROLE_UPDATE.name())));
    }
    private void requireManager(UUID householdId) {
        if (!hasManager(householdId)) throw error(LAST_MANAGER, "At least one member must retain permission to update household roles.");
    }
    private void requireVersion(Long actual, Long expected) {
        if (expected == null || !Objects.equals(actual, expected)) throw error(STALE, "This role or membership has changed. Reload before saving.");
    }
    private void requireMutable(HouseholdRole role) {
        if (Boolean.TRUE.equals(role.getIsSystemRole())) throw error(SYSTEM_ROLE, "System roles are read-only.");
    }
    private static HouseholdRoleManagementException error(HouseholdRoleManagementException.Reason reason, String message) {
        return new HouseholdRoleManagementException(reason, message);
    }
}
