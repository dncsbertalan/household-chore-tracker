#if DEBUG
import Foundation

@MainActor
enum HouseholdRoleUITestFixture {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("--ui-test-roles") }
    static let userId = UUID(uuidString: "2A460DB1-9970-48EA-A93B-C08A66FA6701")!
    static let householdId = UUID(uuidString: "2A460DB1-9970-48EA-A93B-C08A66FA6702")!
    static let adminId = UUID(uuidString: "2A460DB1-9970-48EA-A93B-C08A66FA6703")!
    static let memberRoleId = UUID(uuidString: "2A460DB1-9970-48EA-A93B-C08A66FA6704")!
    static let systemId = UUID(uuidString: "2A460DB1-9970-48EA-A93B-C08A66FA6705")!
    static let memberId = UUID(uuidString: "2A460DB1-9970-48EA-A93B-C08A66FA6706")!
    static let otherMemberId = UUID(uuidString: "2A460DB1-9970-48EA-A93B-C08A66FA6707")!

    static func household() -> HouseholdResponse {
        let arguments = ProcessInfo.processInfo.arguments
        let grants: [HouseholdPermission] = arguments.contains("--ui-test-role-viewer") ? [.roleView]
            : arguments.contains("--ui-test-role-denied") ? [.choreComplete]
            : HouseholdPermission.allCases.filter { $0 != .choreSelfApproveCompletion }
        let administrator = HouseholdResponse.Role(householdRoleId: adminId, householdId: householdId, name: "Administrator",
            isSystemRole: false, permissions: grants.map { .init(name: $0) }, version: 0)
        let member = HouseholdResponse.Role(householdRoleId: memberRoleId, householdId: householdId, name: "Member",
            isSystemRole: false, permissions: [.init(name: .choreComplete)], version: 0)
        let system = HouseholdResponse.Role(householdRoleId: systemId, householdId: householdId, name: "System role",
            isSystemRole: true, permissions: [.init(name: .roleView)], version: 0)
        return HouseholdResponse(householdId: householdId, name: "Maple House", description: "Our shared home", createdByUserId: userId,
            version: 0, roles: [administrator, member, system], creatorMembership: nil,
            members: [.init(householdMemberId: memberId, householdId: householdId, userId: userId, nickname: "Alex",
                            householdRole: administrator, joinedAt: "2026-11-05T12:00:00Z", version: 0),
                      .init(householdMemberId: otherMemberId, householdId: householdId, userId: UUID(), nickname: "Taylor",
                            householdRole: member, joinedAt: "2026-11-05T12:00:00Z", version: 0)])
    }
}

@MainActor
final class HouseholdRoleUITestRepository: HouseholdRepositoryProtocol, HouseholdRoleRepositoryProtocol, ChoreRepositoryProtocol {
    private var home = HouseholdRoleUITestFixture.household()

    func households(accountId: UUID) async throws -> [HouseholdResponse] { [home] }
    func household(id: UUID, accountId: UUID) async throws -> HouseholdResponse { home }
    func create(_ creation: HouseholdCreation) async throws -> HouseholdResponse { throw APIError.invalidResponse }
    func chores(accountId: UUID, householdId: UUID?) async throws -> [ChoreResponse] { [] }
    func chore(id: UUID, accountId: UUID) async throws -> ChoreResponse { throw APIError.invalidResponse }
    func create(_ creation: ChoreCreation) async throws -> ChoreResponse { throw APIError.invalidResponse }
    func update(id: UUID, accountId: UUID, request: UpdateChoreRequest, requestId: UUID) async throws -> ChoreResponse { throw APIError.invalidResponse }
    func perform(id: UUID, accountId: UUID, action: ChoreAction, request: ChoreActionRequest, requestId: UUID) async throws -> ChoreResponse { throw APIError.invalidResponse }

    private var grants: [HouseholdPermission] { home.members.first { $0.userId == HouseholdRoleUITestFixture.userId }?.householdRole.permissions.map(\.name) ?? [] }
    private func result() -> HouseholdRolesResponse {
        let visible = [.roleView, .memberView, .memberInvite, .roleCreate, .roleUpdate, .roleDelete, .memberAssignRole, .memberRemove].contains { grants.contains($0) }
        return HouseholdRolesResponse(household: home,
            permissions: visible ? HouseholdPermission.allCases.map { .init(name: $0, description: nil) } : [],
            actions: .init(canView: visible, canCreate: grants.contains(.roleCreate), canUpdate: grants.contains(.roleUpdate),
                           canDelete: grants.contains(.roleDelete), canAssignRoles: grants.contains(.memberAssignRole), canRemoveMembers: grants.contains(.memberRemove)))
    }
    func roles(householdId: UUID, accountId: UUID) async throws -> HouseholdRolesResponse {
        guard result().actions.canView else { throw APIError.http(statusCode: 403, problem: nil) }
        return result()
    }
    private func beforeMutation(_ grant: HouseholdPermission) async throws {
        try await Task.sleep(for: .milliseconds(300))
        guard grants.contains(grant) else { throw APIError.http(statusCode: 403, problem: nil) }
        if ProcessInfo.processInfo.arguments.contains("--ui-test-role-fails") { throw APIError.transport(.timedOut) }
        if ProcessInfo.processInfo.arguments.contains("--ui-test-role-conflict") { throw failure("household_role_stale") }
    }
    func createRole(householdId: UUID, accountId: UUID, request: SaveHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await beforeMutation(.roleCreate)
        guard !home.roles.contains(where: { $0.name.caseInsensitiveCompare(request.name) == .orderedSame }) else { throw failure("household_role_duplicate_name") }
        let role = HouseholdResponse.Role(householdRoleId: UUID(), householdId: home.id, name: request.name, isSystemRole: false,
            permissions: request.permissions.map { .init(name: $0) }, version: 0)
        replace(roles: home.roles + [role])
        return result()
    }
    func updateRole(householdId: UUID, roleId: UUID, accountId: UUID, request: UpdateHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await beforeMutation(.roleUpdate)
        guard let role = home.roles.first(where: { $0.householdRoleId == roleId }), request.version == role.version else { throw failure("household_role_stale") }
        guard !role.isSystemRole else { throw failure("household_role_system_role") }
        var roles = home.roles
        roles[roles.firstIndex(where: { $0.householdRoleId == roleId })!] = .init(householdRoleId: roleId, householdId: home.id,
            name: request.name, isSystemRole: false, permissions: request.permissions.map { .init(name: $0) }, version: role.version + 1)
        replace(roles: roles)
        return result()
    }
    func deleteRole(householdId: UUID, roleId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await beforeMutation(.roleDelete)
        guard !home.members.contains(where: { $0.householdRole.householdRoleId == roleId }) else { throw failure("household_role_in_use") }
        replace(roles: home.roles.filter { $0.householdRoleId != roleId })
        return result()
    }
    func assignRole(householdId: UUID, memberId: UUID, accountId: UUID, request: AssignHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await beforeMutation(.memberAssignRole)
        guard let member = home.members.first(where: { $0.householdMemberId == memberId }), member.version == request.memberVersion,
              let role = home.roles.first(where: { $0.householdRoleId == request.roleId }), role.version == request.roleVersion else { throw failure("household_role_stale") }
        let updated = home.members.map { current -> HouseholdResponse.Member in
            guard current.householdMemberId == memberId else { return current }
            return .init(householdMemberId: memberId, householdId: home.id, userId: current.userId, nickname: current.nickname,
                         householdRole: role, joinedAt: current.joinedAt, version: current.version + 1)
        }
        replace(roles: home.roles, members: updated)
        return result()
    }
    func removeMember(householdId: UUID, memberId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdMemberRemovalResponse {
        try await beforeMutation(.memberRemove)
        guard let member = home.members.first(where: { $0.householdMemberId == memberId }), member.version == version else { throw failure("household_role_stale") }
        let remaining = home.members.filter { $0.householdMemberId != memberId }
        guard remaining.contains(where: { $0.householdRole.permissions.contains { $0.name == .roleUpdate } }) else { throw failure("household_role_last_manager") }
        replace(roles: home.roles, members: remaining)
        return .init(householdId: householdId, removedMemberId: memberId, management: member.userId == accountId ? nil : result())
    }
    private func replace(roles: [HouseholdResponse.Role], members: [HouseholdResponse.Member]? = nil) {
        let members = (members ?? home.members).map { member in
            HouseholdResponse.Member(householdMemberId: member.householdMemberId, householdId: home.id, userId: member.userId,
                nickname: member.nickname, householdRole: roles.first { $0.householdRoleId == member.householdRole.householdRoleId }!,
                joinedAt: member.joinedAt, version: member.version)
        }
        home = HouseholdResponse(householdId: home.id, name: home.name, description: home.description, createdByUserId: home.createdByUserId,
            version: home.version, roles: roles, creatorMembership: nil, members: members)
    }
    private func failure(_ code: String) -> APIError {
        let problem = try! JSONDecoder().decode(APIProblem.self, from: JSONSerialization.data(withJSONObject: ["code": code]))
        return .http(statusCode: 409, problem: problem)
    }
}

nonisolated struct HouseholdRoleUITestUserService: CurrentUserServiceProtocol {
    func fetchCurrentUser() async throws -> CurrentUser {
        await CurrentUser(id: HouseholdRoleUITestFixture.userId, email: "alex@example.com", firstName: "Alex", lastName: "Example")
    }
}
#endif
