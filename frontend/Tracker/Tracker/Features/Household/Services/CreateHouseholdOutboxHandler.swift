import Foundation

@MainActor
struct CreateHouseholdOutboxHandler: OutboxHandlerProtocol {
    let entityType = OutboxEntityType.household
    let action = OutboxAction.create
    let client: any APIClientProtocol

    func send(_ operation: QueuedOutboxOperation) async throws
        -> any OutboxReconciliationProtocol
    {
        let request = try JSONDecoder().decode(
            CreateHouseholdRequest.self,
            from: operation.payload
        )
        guard request.householdId == operation.entityId else {
            throw OutboxError.invalidResponse
        }
        var endpoint = APIEndpoint(
            path: "households",
            method: .post,
            headers: ["Idempotency-Key": operation.id.uuidString],
            body: operation.payload
        )
        endpoint.expectedAccountId = operation.accountId
        let response = try await client.send(
            endpoint,
            as: HouseholdResponse.self
        )
        let membership = response.creatorMembership
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime, .withFractionalSeconds,
        ]
        let joinedAt =
            formatter.date(from: membership.joinedAt)
            ?? ISO8601DateFormatter().date(from: membership.joinedAt)
        guard response.householdId == request.householdId,
            response.createdByUserId == operation.accountId,
            membership.householdId == request.householdId,
            membership.householdMemberId == request.householdMemberId,
            membership.userId == operation.accountId,
            membership.householdRole.householdRoleId == request.creatorRoleId,
            Set(response.roles.map(\.householdRoleId))
                == Set(request.roles.map(\.householdRoleId)),
            response.roles.count == request.roles.count,
            response.roles.allSatisfy({ $0.householdId == request.householdId }
            ),
            response.roles.contains(membership.householdRole),
            let joinedAt
        else { throw OutboxError.invalidResponse }
        return CreateHouseholdReconciliation(
            response: response,
            joinedAt: joinedAt
        )
    }
}
