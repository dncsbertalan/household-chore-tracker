import Foundation
import SwiftData

@MainActor
struct LocalChoreRepository: ChoreRepositoryProtocol {
    let container: ModelContainer
    private let authorization = HouseholdAuthorizationService()

    func create(_ creation: ChoreCreation) throws {
        guard creation.hasValidDetails else { throw LocalChoreRepositoryError.invalidDetails }
        guard creation.hasValidSchedule else { throw LocalChoreRepositoryError.invalidSchedule }

        // Isolate this save from unrelated UI edits, just like household creation.
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let householdId = creation.householdId
        guard let household = try context.fetch(FetchDescriptor<LocalHousehold>(
            predicate: #Predicate { $0.householdId == householdId && $0.deletedAt == nil }
        )).first else { throw LocalChoreRepositoryError.householdUnavailable }

        let creator = try authorization.requirePermission(.choreCreate, in: household, userId: creation.createdByUserId)

        let members = household.householdMembers.filter { $0.deletedAt == nil }
        let memberIds = Set(members.map(\.householdMemberId))
        let assigneeIds = Set(creation.assignedMemberIds)
        guard assigneeIds.count == creation.assignedMemberIds.count,
              assigneeIds.isSubset(of: memberIds),
              creation.requiredApprovalCount >= 0,
              creation.requiredApprovalCount <= memberIds.count else {
            throw LocalChoreRepositoryError.invalidMembers
        }

        let choreId = creation.choreId
        guard try context.fetchCount(FetchDescriptor<LocalChore>(
            predicate: #Predicate { $0.choreId == choreId }
        )) == 0 else { throw LocalChoreRepositoryError.duplicateID }

        let chore = LocalChore(
            choreId: choreId, title: creation.normalizedTitle,
            choreDescription: creation.normalizedDescription.isEmpty ? nil : creation.normalizedDescription,
            createdByUserId: creation.createdByUserId, household: household,
            assignedMemberIds: creation.assignedMemberIds,
            requiredApprovalCount: creation.requiredApprovalCount,
            createdByHouseholdMemberId: creator.householdMemberId
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
            let request = CreateChoreRequest(creation: creation, chore: chore)
            try OutboxStore.enqueue(OutboxOperation(
                accountId: creation.createdByUserId, entityType: .chore,
                entityId: chore.choreId, action: .create, payload: request
            ), in: context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        NotificationCenter.default.post(name: .outboxDidEnqueue, object: nil)
    }
}
