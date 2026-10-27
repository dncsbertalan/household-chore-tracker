import Foundation
import SwiftData

@MainActor
struct HouseholdInvitationOutboxHandler: OutboxHandlerProtocol {
    let entityType = OutboxEntityType.householdInvitation
    let action: OutboxAction
    let client: any APIClientProtocol

    func send(_ operation: QueuedOutboxOperation) async throws -> any OutboxReconciliationProtocol {
        guard operation.entityType == entityType.rawValue, operation.action == action.rawValue else {
            throw OutboxError.unsupportedOperation
        }
        let command = try JSONDecoder().decode(HouseholdInvitationCommand.self, from: operation.payload)
        let headers = ["Idempotency-Key": operation.id.uuidString]
        switch (action, command) {
        case (.create, .invite(let householdId, let request)):
            guard operation.entityId == householdId,
                  InviteHouseholdMemberRequest.isValidEmail(request.email) else { throw OutboxError.invalidResponse }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            var endpoint = APIEndpoint(path: "households/\(householdId)/invitations", method: .post,
                                       headers: headers, body: try encoder.encode(request))
            endpoint.expectedAccountId = operation.accountId
            let response = try await client.send(endpoint, as: HouseholdInvitationResponse.self)
            guard response.isValid, response.householdId == householdId,
                  response.email == request.email, response.householdRoleId == request.householdRoleId,
                  response.invitedByUserId == operation.accountId, response.status == .pending else {
                throw OutboxError.invalidResponse
            }
            return InvitationDeliveryReconciliation()

        case (.accept, .respond(let invitation)):
            var endpoint = try responseEndpoint(invitation, operation: operation, headers: headers)
            endpoint.expectedAccountId = operation.accountId
            let response = try await client.send(endpoint, as: JoinedHouseholdResponse.self)
            let member = response.membership
            guard response.householdId == invitation.householdId,
                  member.householdId == response.householdId, member.userId == operation.accountId,
                  member.householdRole.householdRoleId == invitation.householdRoleId,
                  response.version >= 0, member.version >= 0,
                  Set(response.roles.map(\.householdRoleId)).count == response.roles.count,
                  response.roles.allSatisfy({ $0.householdId == response.householdId && $0.version >= 0 }),
                  response.roles.contains(member.householdRole),
                  let joinedAt = InvitationTimestamp.date(member.joinedAt) else { throw OutboxError.invalidResponse }
            return JoinedHouseholdReconciliation(response: response, joinedAt: joinedAt)

        case (.decline, .respond(let invitation)):
            let endpoint = try responseEndpoint(invitation, operation: operation, headers: headers)
            let response = try await client.send(endpoint, as: HouseholdInvitationResponse.self)
            guard response.isValid, response.id == invitation.id,
                  response.householdId == invitation.householdId, response.email == invitation.email,
                  response.householdRoleId == invitation.householdRoleId, response.status == .declined else {
                throw OutboxError.invalidResponse
            }
            return InvitationDeliveryReconciliation()

        case (.revoke, .respond(let invitation)):
            let endpoint = try responseEndpoint(invitation, operation: operation, headers: headers)
            try await client.sendWithoutResponse(endpoint)
            return InvitationDeliveryReconciliation()

        default: throw OutboxError.unsupportedOperation
        }
    }

    private func responseEndpoint(_ invitation: HouseholdInvitationResponse, operation: QueuedOutboxOperation,
                                  headers: [String: String]) throws -> APIEndpoint {
        guard invitation.id == operation.entityId, invitation.isValid else { throw OutboxError.invalidResponse }
        // Do not recheck the local clock: a retry may replay an acceptance made before expiry.
        let path = action == .revoke
            ? "households/\(invitation.householdId)/invitations/\(invitation.id)"
            : "household-invitations/\(invitation.id)/\(action.rawValue)"
        var endpoint = APIEndpoint(path: path, method: action == .revoke ? .delete : .post, headers: headers)
        endpoint.expectedAccountId = operation.accountId
        return endpoint
    }
}

@MainActor
private struct InvitationDeliveryReconciliation: OutboxReconciliationProtocol {
    // The sender/inbox lists are fetched from the server. No optimistic membership is created.
    func apply(in context: ModelContext) throws { }
}
