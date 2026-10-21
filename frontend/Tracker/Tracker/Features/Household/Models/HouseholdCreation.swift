import Foundation

nonisolated struct HouseholdCreation {
    let name: String
    let description: String
    let roleName: String
    let permissions: Set<HouseholdPermission>
    let creatorUserId: UUID
    let creatorRoleId: UUID
}
