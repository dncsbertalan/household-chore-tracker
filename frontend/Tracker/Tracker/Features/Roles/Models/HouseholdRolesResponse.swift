import Foundation

nonisolated struct HouseholdRolesResponse: Codable, Sendable {
    let household: Household
    let permissions: [CatalogPermission]
    let actions: Actions

    struct CatalogPermission: Codable, Sendable, Identifiable {
        var id: HouseholdPermission { name }
        let name: HouseholdPermission
        let description: String?
    }
    struct Actions: Codable, Sendable {
        let canView: Bool
        let canCreate: Bool
        let canUpdate: Bool
        let canDelete: Bool
        let canAssignRoles: Bool
        let canRemoveMembers: Bool

        init(canView: Bool, canCreate: Bool, canUpdate: Bool, canDelete: Bool, canAssignRoles: Bool, canRemoveMembers: Bool = false) {
            self.canView = canView; self.canCreate = canCreate; self.canUpdate = canUpdate
            self.canDelete = canDelete; self.canAssignRoles = canAssignRoles; self.canRemoveMembers = canRemoveMembers
        }
        private enum CodingKeys: String, CodingKey { case canView, canCreate, canUpdate, canDelete, canAssignRoles, canRemoveMembers }
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            canView = try values.decode(Bool.self, forKey: .canView)
            canCreate = try values.decode(Bool.self, forKey: .canCreate)
            canUpdate = try values.decode(Bool.self, forKey: .canUpdate)
            canDelete = try values.decode(Bool.self, forKey: .canDelete)
            canAssignRoles = try values.decode(Bool.self, forKey: .canAssignRoles)
            canRemoveMembers = try values.decodeIfPresent(Bool.self, forKey: .canRemoveMembers) ?? false
        }
    }
}
