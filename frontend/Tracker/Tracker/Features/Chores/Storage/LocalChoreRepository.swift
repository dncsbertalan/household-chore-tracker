import Foundation
import SwiftData

@MainActor
struct LocalChoreRepository: ChoreRepositoryProtocol {
    let container: ModelContainer

    func create(_ creation: ChoreCreation) throws {
        guard creation.hasValidDetails else { throw LocalChoreStoreError.invalidDetails }
        guard creation.hasValidSchedule else { throw LocalChoreStoreError.invalidSchedule }

        // Isolate this save from unrelated UI edits, just like household creation.
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let householdId = creation.householdId
        guard let household = try context.fetch(FetchDescriptor<LocalHousehold>(
            predicate: #Predicate { $0.householdId == householdId && $0.deletedAt == nil }
        )).first else { throw LocalChoreStoreError.householdUnavailable }

        guard household.hasPermission(.choreCreate, userId: creation.createdByUserId) else {
            throw LocalChoreStoreError.permissionDenied
        }

        let members = household.householdMembers.filter { $0.deletedAt == nil }
        let memberIds = Set(members.map(\.householdMemberId))
        let assigneeIds = Set(creation.assignedMemberIds)
        guard assigneeIds.count == creation.assignedMemberIds.count,
              assigneeIds.isSubset(of: memberIds),
              creation.requiredApprovalCount >= 0,
              creation.requiredApprovalCount <= memberIds.count else {
            throw LocalChoreStoreError.invalidMembers
        }

        let choreId = creation.choreId
        guard try context.fetchCount(FetchDescriptor<LocalChore>(
            predicate: #Predicate { $0.choreId == choreId }
        )) == 0 else { throw LocalChoreStoreError.duplicateID }

        let chore = LocalChore(
            choreId: choreId, title: creation.normalizedTitle,
            choreDescription: creation.normalizedDescription.isEmpty ? nil : creation.normalizedDescription,
            createdByUserId: creation.createdByUserId, household: household,
            assignedMemberIds: creation.assignedMemberIds,
            requiredApprovalCount: creation.requiredApprovalCount
        )
        context.insert(chore)

        if let scheduleType = creation.pattern.scheduleType {
            let schedule = LocalChoreSchedule(
                chore: chore, scheduleType: scheduleType,
                recurrenceUnit: scheduleType == .onDemand ? nil : creation.recurrenceUnit,
                recurrenceInterval: creation.recurrenceInterval,
                startsAt: creation.scheduledAt,
                timeZoneIdentifier: creation.timeZoneIdentifier
            )
            context.insert(schedule)
            chore.schedule = schedule
        }

        // On-demand chores remain templates until someone requests a task.
        if creation.pattern != .onDemand {
            let occurrence = LocalChoreOccurrence(
                chore: chore, scheduledAt: creation.scheduledAt, dueAt: creation.dueAt
            )
            context.insert(occurrence)
            chore.occurrences = [occurrence]
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        // Chore API/outbox delivery is not available yet; these records remain pending locally.
    }
}

nonisolated enum LocalChoreStoreError: Error {
    case invalidDetails
    case invalidSchedule
    case invalidMembers
    case householdUnavailable
    case permissionDenied
    case duplicateID
}
