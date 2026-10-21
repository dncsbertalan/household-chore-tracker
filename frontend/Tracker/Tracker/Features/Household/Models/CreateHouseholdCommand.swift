import Foundation

/// Version 1 of the creation intent stored in the outbox, independent of live SwiftData state.
nonisolated struct CreateHouseholdCommand: Codable, Sendable, Equatable {
    static let commandType: OutboxCommandType = .createHousehold
    static let payloadVersion = 1

    let householdId: UUID
    let name: String
    let description: String?
    let roles: [Role]
    let creatorRoleId: UUID
    let householdMemberId: UUID

    

    nonisolated struct Role: Codable, Sendable, Equatable {
        let householdRoleId: UUID
        let name: String
        let permissions: [String]
    }
}
