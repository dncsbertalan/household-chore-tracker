import Foundation

nonisolated protocol HouseholdInvitationServiceProtocol: Sendable {
    func invite(email: String, householdId: UUID, roleId: UUID, accountId: UUID,
                requestId: UUID) async throws -> HouseholdInvitationResponse
    func accept(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws -> JoinedHouseholdResponse
    func decline(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws -> HouseholdInvitationResponse
    func revoke(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws
    func inbox(accountId: UUID) async throws -> [HouseholdInvitationResponse]
    func invitation(id: UUID, accountId: UUID) async throws -> HouseholdInvitationResponse
    func sent(householdId: UUID, accountId: UUID) async throws -> [HouseholdInvitationResponse]
}

/// Account-bound invitation requests use the backend as their source of truth.
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

    func invite(email: String, householdId: UUID, roleId: UUID, accountId: UUID,
                requestId: UUID) async throws -> HouseholdInvitationResponse {
        let request = InviteHouseholdMemberRequest(email: email, householdRoleId: roleId)
        guard InviteHouseholdMemberRequest.isValidEmail(request.email) else { throw HouseholdInvitationError.invalidEmail }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var endpoint = APIEndpoint(path: "households/\(householdId)/invitations", method: .post,
                                   headers: ["Idempotency-Key": requestId.uuidString], body: try encoder.encode(request))
        endpoint.expectedAccountId = accountId
        endpoint.timeout = 30
        let response = try await client.send(endpoint, as: HouseholdInvitationResponse.self)
        guard response.isValid, response.householdId == householdId, response.email == request.email,
              response.householdRoleId == roleId, response.invitedByUserId == accountId,
              response.status == .pending else { throw APIError.invalidResponse }
        return response
    }

    func accept(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws -> JoinedHouseholdResponse {
        let response = try await client.send(responseEndpoint(invitation, action: "accept", accountId: accountId, requestId: requestId),
                                             as: JoinedHouseholdResponse.self)
        let member = response.membership
        guard response.householdId == invitation.householdId,
              member.householdId == response.householdId, member.userId == accountId,
              member.householdRole.householdRoleId == invitation.householdRoleId,
              response.version >= 0, member.version >= 0,
              Set(response.roles.map(\.householdRoleId)).count == response.roles.count,
              response.roles.allSatisfy({ $0.householdId == response.householdId && $0.version >= 0 }),
              response.roles.contains(member.householdRole),
              InvitationTimestamp.date(member.joinedAt) != nil else { throw APIError.invalidResponse }
        return response
    }

    func decline(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws -> HouseholdInvitationResponse {
        let response = try await client.send(responseEndpoint(invitation, action: "decline", accountId: accountId, requestId: requestId),
                                             as: HouseholdInvitationResponse.self)
        guard response.isValid, response.id == invitation.id, response.householdId == invitation.householdId,
              response.email == invitation.email, response.householdRoleId == invitation.householdRoleId,
              response.status == .declined else { throw APIError.invalidResponse }
        return response
    }

    func revoke(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws {
        try await client.sendWithoutResponse(responseEndpoint(invitation, action: "revoke", accountId: accountId, requestId: requestId))
    }

    private func responseEndpoint(_ invitation: HouseholdInvitationResponse, action: String, accountId: UUID, requestId: UUID) throws -> APIEndpoint {
        guard invitation.isValid else { throw APIError.invalidResponse }
        let path = action == "revoke"
            ? "households/\(invitation.householdId)/invitations/\(invitation.id)"
            : "household-invitations/\(invitation.id)/\(action)"
        var endpoint = APIEndpoint(path: path, method: action == "revoke" ? .delete : .post,
                                   headers: ["Idempotency-Key": requestId.uuidString])
        endpoint.expectedAccountId = accountId
        endpoint.timeout = 30
        return endpoint
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
