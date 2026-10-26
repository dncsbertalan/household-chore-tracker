import Foundation

extension HouseholdResponse {
    nonisolated struct Permission: Decodable, Sendable, Equatable {
        let name: HouseholdPermission
    }
}
