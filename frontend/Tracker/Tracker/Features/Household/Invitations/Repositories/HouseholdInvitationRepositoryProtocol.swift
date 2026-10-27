import Foundation

@MainActor
protocol HouseholdInvitationRepositoryProtocol {
    func invite(email: String, householdId: UUID, roleId: UUID, accountId: UUID) throws -> UUID
    func accept(_ invitation: HouseholdInvitationResponse, accountId: UUID) throws -> UUID
    func decline(_ invitation: HouseholdInvitationResponse, accountId: UUID) throws -> UUID
    func revoke(_ invitation: HouseholdInvitationResponse, accountId: UUID) throws -> UUID
    func pending(accountId: UUID) throws -> [PendingHouseholdInvitation]
}
