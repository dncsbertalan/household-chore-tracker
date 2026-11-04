import Foundation

nonisolated struct HouseholdCreation: Equatable {
    var requestId = UUID()
    var householdId = UUID()
    var householdMemberId = UUID()
    let name: String
    let description: String
    let roleName: String
    let permissions: Set<HouseholdPermission>
    let creatorUserId: UUID
    let creatorRoleId: UUID
}
