import SwiftData

/// The app and previews must use the same schema for atomic entity and command saves.
@MainActor
enum TrackerSchema {
    static let models: [any PersistentModel.Type] = [
        LocalHousehold.self, LocalHouseholdRole.self, LocalHouseholdMember.self,
        OutboxRecord.self, SyncRetryRecord.self
    ]
    static let schema = Schema(models)
}
