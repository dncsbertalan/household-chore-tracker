import SwiftData

@MainActor
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        LocalHousehold.self, LocalHouseholdRole.self, LocalHouseholdMember.self,
        LocalChore.self, LocalChoreSchedule.self, LocalChoreOccurrence.self,
        LocalChoreCompletion.self, LocalChoreApproval.self, OutboxEntry.self,
    ]
    static let schema = Schema(models)
}
