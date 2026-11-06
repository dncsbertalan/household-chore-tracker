#if DEBUG
import Foundation

/// Each preview owns an isolated repository; no API or credentials are used.
@MainActor
enum HouseholdRolesPreview {
    static let accountId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let householdId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static var data: HouseholdRolesResponse {
        let manager = HouseholdRole(householdRoleId: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            householdId: householdId, name: "Manager", isSystemRole: true,
            permissions: HouseholdPermission.allCases.map { .init(name: $0) }, version: 1)
        let helper = HouseholdRole(householdRoleId: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            householdId: householdId, name: "Housemate", isSystemRole: false,
            permissions: [.init(name: .choreSelfApproveCompletion)], version: 2)
        let members = [
            HouseholdMember(householdMemberId: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                householdId: householdId, nickname: "Alex (you)",
                userInfo: .init(userId: accountId, email: "alex@example.com", firstName: "Alex", lastName: "Example"),
                householdRole: manager,
                joinedAt: "2026-10-01T10:00:00Z", version: 1),
            HouseholdMember(householdMemberId: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
                householdId: householdId, nickname: "Sam",
                userInfo: .init(userId: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
                    email: "sam@example.com", firstName: "Sam", lastName: "Example"),
                householdRole: helper, joinedAt: "2026-10-02T10:00:00Z", version: 1)
        ]
        return .init(household: .init(householdId: householdId, name: "Our home", description: "Shared chores",
            createdByUserId: accountId, version: 1, roles: [manager, helper], creatorMembership: members[0], members: members),
            permissions: HouseholdPermission.allCases.map { .init(name: $0, description: nil) },
            actions: .init(canView: true, canCreate: true, canUpdate: true, canDelete: true, canAssignRoles: true, canRemoveMembers: true))
    }

    static func repository() -> any HouseholdRoleRepositoryProtocol {
        HouseholdRolesPreviewRepository()
    }
}

@MainActor
private final class HouseholdRolesPreviewRepository: HouseholdRoleRepositoryProtocol {
    private var data = HouseholdRolesPreview.data

    func roles(householdId: UUID, accountId: UUID) async throws -> HouseholdRolesResponse { data }

    func createRole(householdId: UUID, accountId: UUID, request: SaveHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        let role = HouseholdRole(householdRoleId: UUID(), householdId: householdId,
            name: request.name, isSystemRole: false, permissions: request.permissions.map { .init(name: $0) }, version: 1)
        replace(roles: data.household.roles + [role], members: data.household.members)
        return data
    }

    func updateRole(householdId: UUID, roleId: UUID, accountId: UUID, request: UpdateHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        let role = HouseholdRole(householdRoleId: roleId, householdId: householdId,
            name: request.name, isSystemRole: false, permissions: request.permissions.map { .init(name: $0) }, version: request.version + 1)
        replace(roles: data.household.roles.map { $0.householdRoleId == roleId ? role : $0 },
            members: data.household.members.map { member in
                member.householdRole.householdRoleId == roleId ? assigning(role, to: member) : member
            })
        return data
    }

    func deleteRole(householdId: UUID, roleId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdRolesResponse {
        guard !data.household.members.contains(where: { $0.householdRole.householdRoleId == roleId }) else {
            throw APIError.http(statusCode: 409, problem: .init(type: nil, title: nil, status: 409,
                detail: nil, instance: nil, errors: nil, code: "household_role_in_use"))
        }
        replace(roles: data.household.roles.filter { $0.householdRoleId != roleId }, members: data.household.members)
        return data
    }

    func assignRole(householdId: UUID, memberId: UUID, accountId: UUID, request: AssignHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        guard let role = data.household.roles.first(where: { $0.householdRoleId == request.roleId }) else { throw APIError.invalidResponse }
        replace(roles: data.household.roles, members: data.household.members.map {
            $0.householdMemberId == memberId ? assigning(role, to: $0) : $0
        })
        return data
    }

    func removeMember(householdId: UUID, memberId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdMemberRemovalResponse {
        let leaving = data.household.members.first { $0.householdMemberId == memberId }?.userInfo.userId == accountId
        replace(roles: data.household.roles, members: data.household.members.filter { $0.householdMemberId != memberId })
        return .init(householdId: householdId, removedMemberId: memberId, management: leaving ? nil : data)
    }

    private func assigning(_ role: HouseholdRole, to member: HouseholdMember) -> HouseholdMember {
        .init(householdMemberId: member.householdMemberId, householdId: member.householdId,
            nickname: member.nickname, userInfo: member.userInfo, householdRole: role, joinedAt: member.joinedAt, version: member.version + 1)
    }

    private func replace(roles: [HouseholdRole], members: [HouseholdMember]) {
        let household = data.household
        data = .init(household: .init(householdId: household.id, name: household.name, description: household.description,
            createdByUserId: household.createdByUserId, version: household.version + 1, roles: roles,
            creatorMembership: members.first { $0.userInfo.userId == household.createdByUserId }, members: members),
            permissions: data.permissions, actions: data.actions)
    }
}
#endif
