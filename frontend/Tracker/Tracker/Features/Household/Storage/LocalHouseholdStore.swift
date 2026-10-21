import Foundation
import SwiftData

@MainActor
struct LocalHouseholdStore: HouseholdRepository {
    static let schema = TrackerSchema.schema
    let container: ModelContainer
    
    func create() async throws {
        /*let context = ModelContext(container)
        context.autosaveEnabled = false
        
        let memberId = draft.creatorMembership.householdMemberId
        let roleIds = draft.roles.map(\.householdRoleId)
     
        // Encode the creation snapshot before inserting anything into the context.
        let command = OutboxCommand(
            accountId: draft.creatorMembership.userId, aggregateId: householdId,
            commandType: CreateHouseholdCommand.commandType,
            payloadVersion: CreateHouseholdCommand.payloadVersion,
            payload: try JSONEncoder().encode(CreateHouseholdCommand(draft: draft))
        )
        let household = LocalHousehold(draft: draft)
        household.creationCommandId = command.id
        
        context.insert(household)
        household.roles = draft.roles.enumerated().map { position, draft in
            LocalHouseholdRole(draft: draft, position: position)
        }
        let member = LocalHouseholdMember(draft: draft.creatorMembership)
        member.role = household.roles.first { $0.householdRoleId == draft.creatorMembership.householdRoleId }
        household.householdMembers = [member]
        context.insert(OutboxRecord(command: command))
        
        do {
            // A single save commits both the graph and its delivery intent, or neither.
            try context.save()
        } catch {
            context.rollback()
            throw error
        }*/
    }
    
    func save() async throws {
        /*// A dedicated context prevents autosave or rollback from touching unrelated UI edits.
        let context = ModelContext(container)
        context.autosaveEnabled = false
        
        let householdId = draft.householdId
        let memberId = draft.creatorMembership.householdMemberId
        let roleIds = draft.roles.map(\.householdRoleId)
        
        guard try context.fetchCount(FetchDescriptor<LocalHousehold>(
            predicate: #Predicate { $0.householdId == householdId }
        )) == 0,
              try context.fetchCount(FetchDescriptor<LocalHouseholdMember>(
                predicate: #Predicate { $0.householdMemberId == memberId }
              )) == 0,
              try context.fetchCount(FetchDescriptor<LocalHouseholdRole>(
                predicate: #Predicate { roleIds.contains($0.householdRoleId) }
              )) == 0 else { throw LocalHouseholdStoreError.duplicateID }
        
        // Encode the creation snapshot before inserting anything into the context.
        let command = OutboxCommand(
            accountId: draft.creatorMembership.userId, aggregateId: householdId,
            commandType: CreateHouseholdCommand.commandType,
            payloadVersion: CreateHouseholdCommand.payloadVersion,
            payload: try JSONEncoder().encode(CreateHouseholdCommand(draft: draft))
        )
        let household = LocalHousehold(draft: draft)
        household.creationCommandId = command.id
        
        context.insert(household)
        household.roles = draft.roles.enumerated().map { position, draft in
            LocalHouseholdRole(draft: draft, position: position)
        }
        let member = LocalHouseholdMember(draft: draft.creatorMembership)
        member.role = household.roles.first { $0.householdRoleId == draft.creatorMembership.householdRoleId }
        household.householdMembers = [member]
        context.insert(OutboxRecord(command: command))
        
        do {
            // A single save commits both the graph and its delivery intent, or neither.
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        NotificationCenter.default.post(name: .outboxCommandEnqueued, object: container)
         */
    }
}

nonisolated enum LocalHouseholdStoreError: Error {
    case duplicateID
}
