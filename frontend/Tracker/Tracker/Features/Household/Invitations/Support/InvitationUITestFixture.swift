#if DEBUG
import Foundation

/// Opt-in UI test responses; no connection to the live API.
@MainActor
enum InvitationUITestFixture {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("--ui-test-invitations") }
    static let userId = UUID(uuidString: "0A460DB1-9970-48EA-A93B-C08A66FA6701")!
    static let householdId = UUID(uuidString: "0A460DB1-9970-48EA-A93B-C08A66FA6702")!

    static var household: Household {
        let arguments = ProcessInfo.processInfo.arguments
        let grants: [HouseholdPermission] = arguments.contains("--ui-test-no-invite-permission") ? [] : [.memberInvite]
        let administrator = HouseholdRole(householdRoleId: UUID(), householdId: householdId,
            name: "Administrator", isSystemRole: false, permissions: grants.map { .init(name: $0) }, version: 0)
        let role = HouseholdRole(householdRoleId: UUID(), householdId: householdId,
            name: "Member", isSystemRole: false, permissions: [.init(name: .choreCreate), .init(name: .choreComplete)], version: 0)
        let member = HouseholdMember(householdMemberId: UUID(), householdId: householdId,
            nickname: nil,
            userInfo: .init(userId: userId, email: "alex@example.com", firstName: "Alex", lastName: "Example"),
            householdRole: administrator, joinedAt: "2026-10-27T12:00:00Z", version: 0)
        return Household(householdId: householdId, name: "Maple House", description: "Our shared home",
            createdByUserId: arguments.contains("--ui-test-inviter-is-member") ? UUID() : userId, version: 0,
            roles: [administrator, role], creatorMembership: nil, members: [member])
    }
}

@MainActor
struct InvitationUITestHouseholdRepository: HouseholdRepositoryProtocol, ChoreRepositoryProtocol {
    func chore(id: UUID, accountId: UUID) async throws -> ChoreResponse { throw APIError.invalidResponse }
    func update(id: UUID, accountId: UUID, request: UpdateChoreRequest, requestId: UUID) async throws -> ChoreResponse { throw APIError.invalidResponse }
    func perform(id: UUID, accountId: UUID, action: ChoreAction, request: ChoreActionRequest, requestId: UUID) async throws -> ChoreResponse { throw APIError.invalidResponse }
    func chores(accountId: UUID, householdId: UUID?) async throws -> [ChoreResponse] { [] }
    func create(_ creation: ChoreCreation) async throws -> ChoreResponse { throw APIError.invalidResponse }
    private let response = InvitationUITestFixture.household
    func households(accountId: UUID) async throws -> [Household] { [response] }
    func household(id: UUID, accountId: UUID) async throws -> Household { response }
    func create(_ creation: HouseholdCreation) async throws -> Household { throw APIError.invalidResponse }
}

nonisolated struct InvitationUITestUserService: CurrentUserServiceProtocol {
    func fetchCurrentUser() async throws -> CurrentUser {
        await CurrentUser(id: InvitationUITestFixture.userId, email: "alex@example.com", firstName: "Alex", lastName: "Example")
    }
}

nonisolated struct InvitationUITestService: HouseholdInvitationServiceProtocol {
    func inbox(accountId: UUID) async throws -> [HouseholdInvitationResponse] { [] }
    func sent(householdId: UUID, accountId: UUID) async throws -> [HouseholdInvitationResponse] { [] }
    func invitation(id: UUID, accountId: UUID) async throws -> HouseholdInvitationResponse { throw APIError.invalidResponse }
    func invite(email: String, householdId: UUID, roleId: UUID, accountId: UUID, requestId: UUID) async throws -> HouseholdInvitationResponse {
        try await Task.sleep(for: .seconds(2))
        if ProcessInfo.processInfo.arguments.contains("--ui-test-send-fails") { throw APIError.transport(.timedOut) }
        return HouseholdInvitationResponse(householdInvitationId: requestId, householdId: householdId,
            householdName: "Maple House", email: email, invitedByUserId: accountId,
            householdRoleId: roleId, householdRoleName: "Member", status: .pending,
            expiresAt: "2099-11-03T12:00:00Z", respondedAt: nil,
            createdAt: "2026-10-27T12:00:00Z", updatedAt: "2026-10-27T12:00:00Z", version: 0)
    }
    func accept(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws -> JoinedHouseholdResponse { throw APIError.invalidResponse }
    func decline(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws -> HouseholdInvitationResponse { throw APIError.invalidResponse }
    func revoke(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws { }
}
#endif
