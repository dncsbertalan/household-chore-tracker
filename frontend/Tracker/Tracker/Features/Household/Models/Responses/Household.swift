import Foundation

nonisolated struct Household: Codable, Sendable, Identifiable {
    let householdId: UUID
    let name: String
    let description: String?
    
    let createdByUserId: UUID
    
    let version: Int64
    let roles: [HouseholdRole]
    let creatorMembership: HouseholdMember?
    
    let members: [HouseholdMember]

    var id: UUID { householdId }
}
