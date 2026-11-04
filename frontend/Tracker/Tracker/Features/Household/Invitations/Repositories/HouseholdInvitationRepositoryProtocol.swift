import Foundation

@MainActor
protocol HouseholdInvitationRepositoryProtocol {
    func invite(email: String, householdId: UUID, roleId: UUID, accountId: UUID,
                requestId: UUID) async throws -> HouseholdInvitationResponse
    func accept(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws
    func decline(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws
    func revoke(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws
}
