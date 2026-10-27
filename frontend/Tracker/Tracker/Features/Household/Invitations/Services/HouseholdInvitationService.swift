import Foundation

nonisolated protocol HouseholdInvitationServiceProtocol: Sendable {
    func inbox(accountId: UUID) async throws -> [HouseholdInvitationResponse]
    func invitation(id: UUID, accountId: UUID) async throws -> HouseholdInvitationResponse
    func sent(householdId: UUID, accountId: UUID) async throws -> [HouseholdInvitationResponse]
}

/// Reads use the authenticated client. Writes are delivered by the durable outbox handler.
nonisolated struct HouseholdInvitationService: HouseholdInvitationServiceProtocol {
    let client: any APIClientProtocol

    func inbox(accountId: UUID) async throws -> [HouseholdInvitationResponse] {
        let invitations: [HouseholdInvitationResponse] = try await fetch("household-invitations", accountId: accountId)
        try validate(invitations)
        guard invitations.allSatisfy({ $0.status == .pending }) else { throw APIError.invalidResponse }
        return invitations
    }

    func invitation(id: UUID, accountId: UUID) async throws -> HouseholdInvitationResponse {
        let invitation: HouseholdInvitationResponse = try await fetch("household-invitations/\(id)", accountId: accountId)
        try validate([invitation])
        guard invitation.id == id else { throw APIError.invalidResponse }
        return invitation
    }

    func sent(householdId: UUID, accountId: UUID) async throws -> [HouseholdInvitationResponse] {
        let invitations: [HouseholdInvitationResponse] = try await fetch("households/\(householdId)/invitations", accountId: accountId)
        try validate(invitations)
        guard invitations.allSatisfy({ $0.householdId == householdId }) else { throw APIError.invalidResponse }
        return invitations
    }

    private func fetch<Response: Decodable & Sendable>(_ path: String, accountId: UUID) async throws -> Response {
        var endpoint = APIEndpoint(path: path)
        endpoint.expectedAccountId = accountId
        endpoint.retryPolicy = .transientReads
        return try await client.send(endpoint, as: Response.self)
    }

    private func validate(_ invitations: [HouseholdInvitationResponse]) throws {
        guard invitations.allSatisfy(\.isValid), Set(invitations.map(\.id)).count == invitations.count else {
            throw APIError.invalidResponse
        }
    }
}
