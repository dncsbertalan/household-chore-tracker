import Foundation

nonisolated struct UpdateHouseholdRequest: Encodable, Equatable, Sendable {
    let name: String
    let description: String?
    let version: Int64
}
