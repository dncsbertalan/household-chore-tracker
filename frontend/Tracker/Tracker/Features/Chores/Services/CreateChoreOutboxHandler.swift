import Foundation

@MainActor
struct CreateChoreOutboxHandler: OutboxHandlerProtocol {
    let entityType = OutboxEntityType.chore
    let action = OutboxAction.create
    let client: any APIClientProtocol

    func send(_ operation: QueuedOutboxOperation) async throws -> any OutboxReconciliationProtocol {
        let request = try JSONDecoder().decode(CreateChoreRequest.self, from: operation.payload)
        guard request.choreId == operation.entityId else { throw OutboxError.invalidResponse }
        var endpoint = APIEndpoint(
            path: "chores", method: .post,
            headers: ["Idempotency-Key": operation.id.uuidString], body: operation.payload
        )
        endpoint.expectedAccountId = operation.accountId
        let response = try await client.send(endpoint, as: ChoreResponse.self)
        guard response.choreId == request.choreId,
              response.householdId == request.householdId,
              response.createdByUserId == operation.accountId,
              response.updatedByHouseholdMemberId == response.createdByHouseholdMemberId,
              response.version >= 0,
              response.title == request.title,
              response.description == request.description,
              Set(response.assignedMemberIds) == Set(request.assignedMemberIds),
              response.assignedMemberIds.count == request.assignedMemberIds.count,
              response.requiredApprovalCount == request.requiredApprovalCount,
              response.schedule?.choreScheduleId == request.choreScheduleId,
              response.occurrence?.choreOccurrenceId == request.choreOccurrenceId else {
            throw OutboxError.invalidResponse
        }
        if let schedule = response.schedule {
            guard schedule.scheduleType == request.pattern.scheduleType,
                  schedule.recurrenceUnit == request.recurrenceUnit,
                  schedule.recurrenceInterval == request.recurrenceInterval,
                  try sameInstant(schedule.startsAt, request.scheduledAt),
                  schedule.timeZoneIdentifier == request.timeZoneIdentifier,
                  schedule.createdByHouseholdMemberId == response.createdByHouseholdMemberId,
                  schedule.updatedByHouseholdMemberId == response.createdByHouseholdMemberId,
                  schedule.version >= 0 else { throw OutboxError.invalidResponse }
        }
        if let occurrence = response.occurrence {
            guard occurrence.title == response.title, occurrence.description == response.description,
                  Set(occurrence.assignedMemberIds) == Set(request.assignedMemberIds),
                  occurrence.assignedMemberIds.count == request.assignedMemberIds.count,
                  occurrence.requiredApprovalCount == request.requiredApprovalCount,
                  try sameInstant(occurrence.scheduledAt, request.scheduledAt),
                  try sameInstant(occurrence.dueAt, request.dueAt),
                  occurrence.occurrenceStatus == .pending,
                  occurrence.createdByHouseholdMemberId == response.createdByHouseholdMemberId,
                  occurrence.updatedByHouseholdMemberId == response.createdByHouseholdMemberId,
                  occurrence.version >= 0 else { throw OutboxError.invalidResponse }
        }
        // Validate timestamps before allowing acknowledgement to change local records.
        _ = try ChoreTimestamp.decode(response.createdAt)
        _ = try response.updatedAt.map(ChoreTimestamp.decode)
        _ = try response.schedule?.createdAt.map(ChoreTimestamp.decode)
        _ = try response.schedule?.updatedAt.map(ChoreTimestamp.decode)
        _ = try response.occurrence?.updatedAt.map(ChoreTimestamp.decode)
        if let schedule = response.schedule, let startsAt = schedule.startsAt {
            _ = try ChoreTimestamp.decode(startsAt)
        }
        if let occurrence = response.occurrence { _ = try ChoreTimestamp.decode(occurrence.createdAt) }
        return CreateChoreReconciliation(response: response)
    }

    private func sameInstant(_ first: String?, _ second: String?) throws -> Bool {
        switch (first, second) {
        case (nil, nil): return true
        case let (first?, second?):
            return abs(try ChoreTimestamp.decode(first).timeIntervalSince(ChoreTimestamp.decode(second))) < 0.001
        default: return false
        }
    }
}
