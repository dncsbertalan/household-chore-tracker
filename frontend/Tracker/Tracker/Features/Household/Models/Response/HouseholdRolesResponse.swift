import Foundation

nonisolated struct HouseholdRolesResponse: Decodable, Sendable {
    let household: HouseholdResponse
    let actions: Actions
    
    struct Actions: Decodable, Sendable {
        let canView: Bool
        let canUpdate: Bool
        var canCreate = false
    }
}
