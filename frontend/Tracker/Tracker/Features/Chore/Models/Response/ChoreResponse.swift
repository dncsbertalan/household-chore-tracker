import Foundation

nonisolated struct ChoreResponse: Decodable, Identifiable, Sendable {
    let choreId: UUID
    let householdId: UUID
    let title: String
    let description: String?

    var id: UUID { choreId }
}
