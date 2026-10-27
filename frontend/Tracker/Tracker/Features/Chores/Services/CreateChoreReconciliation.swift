import Foundation
import SwiftData

@MainActor
struct CreateChoreReconciliation: OutboxReconciliationProtocol {
    let response: ChoreResponse

    func apply(in context: ModelContext) throws {
        let id = response.choreId
        guard let chore = try context.fetch(FetchDescriptor<LocalChore>(
            predicate: #Predicate { $0.choreId == id }
        )).first,
              chore.household.householdId == response.householdId,
              chore.createdByUserId == response.createdByUserId,
              (response.createdByHouseholdMemberId == nil || chore.createdByHouseholdMemberId == nil
                  || response.createdByHouseholdMemberId == chore.createdByHouseholdMemberId),
              chore.schedule?.choreScheduleId == response.schedule?.choreScheduleId,
              Set(chore.occurrences.map(\.choreOccurrenceId)) == Set([response.occurrence?.choreOccurrenceId].compactMap { $0 })
        else { throw OutboxError.missingEntity }

        let createdAt = try ChoreTimestamp.decode(response.createdAt)
        let startsAt = try response.schedule?.startsAt.map(ChoreTimestamp.decode)
        let occurrenceCreatedAt = try response.occurrence.map { try ChoreTimestamp.decode($0.createdAt) }
        let scheduledAt = try response.occurrence?.scheduledAt.map(ChoreTimestamp.decode)
        let dueAt = try response.occurrence?.dueAt.map(ChoreTimestamp.decode)
        let updatedAt = try response.updatedAt.map(ChoreTimestamp.decode)
        let scheduleCreatedAt = try response.schedule?.createdAt.map(ChoreTimestamp.decode)
        let scheduleUpdatedAt = try response.schedule?.updatedAt.map(ChoreTimestamp.decode)
        let occurrenceUpdatedAt = try response.occurrence?.updatedAt.map(ChoreTimestamp.decode)

        if chore.localRevision == 1 {
            chore.title = response.title
            chore.choreDescription = response.description
            chore.assignedMemberIds = response.assignedMemberIds
            chore.requiredApprovalCount = response.requiredApprovalCount
            if let updatedAt { chore.updatedAt = updatedAt }
            if let updatedBy = response.updatedByHouseholdMemberId { chore.updatedByHouseholdMemberId = updatedBy }
            if chore.deletedAt == nil { chore.markSynced(serverVersion: response.version) }
            else { chore.serverVersion = response.version }
        } else { chore.serverVersion = response.version }
        chore.createdAt = createdAt
        if let createdBy = response.createdByHouseholdMemberId { chore.createdByHouseholdMemberId = createdBy }

        if let schedule = chore.schedule, let received = response.schedule {
            if schedule.localRevision == 1 {
                schedule.scheduleType = received.scheduleType
                schedule.recurrenceUnit = received.recurrenceUnit
                schedule.recurrenceInterval = received.recurrenceInterval
                schedule.startsAt = startsAt
                schedule.timeZoneIdentifier = received.timeZoneIdentifier
                if let scheduleUpdatedAt { schedule.updatedAt = scheduleUpdatedAt }
                if let updatedBy = received.updatedByHouseholdMemberId { schedule.updatedByHouseholdMemberId = updatedBy }
                if schedule.deletedAt == nil { schedule.markSynced(serverVersion: received.version) }
                else { schedule.serverVersion = received.version }
            } else { schedule.serverVersion = received.version }
            if let scheduleCreatedAt { schedule.createdAt = scheduleCreatedAt }
            if let createdBy = received.createdByHouseholdMemberId { schedule.createdByHouseholdMemberId = createdBy }
        }
        if let occurrence = chore.occurrences.first, let received = response.occurrence,
           let occurrenceCreatedAt {
            if occurrence.localRevision == 1 {
                occurrence.title = received.title
                occurrence.choreDescription = received.description
                occurrence.assignedMemberIds = received.assignedMemberIds
                occurrence.requiredApprovalCount = received.requiredApprovalCount
                occurrence.scheduledAt = scheduledAt
                occurrence.dueAt = dueAt
                occurrence.occurrenceStatus = received.occurrenceStatus
                if let occurrenceUpdatedAt { occurrence.updatedAt = occurrenceUpdatedAt }
                if let updatedBy = received.updatedByHouseholdMemberId { occurrence.updatedByHouseholdMemberId = updatedBy }
                if occurrence.deletedAt == nil { occurrence.markSynced(serverVersion: received.version) }
                else { occurrence.serverVersion = received.version }
            } else { occurrence.serverVersion = received.version }
            occurrence.createdAt = occurrenceCreatedAt
            if let createdBy = received.createdByHouseholdMemberId { occurrence.createdByHouseholdMemberId = createdBy }
        }
    }
}
