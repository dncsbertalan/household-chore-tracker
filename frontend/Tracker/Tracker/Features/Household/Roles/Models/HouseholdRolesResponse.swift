import Foundation

nonisolated struct HouseholdRolesResponse: Decodable, Sendable {
    let household: HouseholdResponse
    let permissions: [CatalogPermission]
    let actions: Actions

    struct CatalogPermission: Decodable, Sendable, Identifiable {
        var id: HouseholdPermission { name }
        let name: HouseholdPermission
        let description: String?
    }
    struct Actions: Decodable, Sendable {
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

nonisolated struct SaveHouseholdRoleRequest: Encodable, Equatable, Sendable {
    let name: String
    let permissions: [HouseholdPermission]
}
nonisolated struct UpdateHouseholdRoleRequest: Encodable, Equatable, Sendable {
    let name: String
    let permissions: [HouseholdPermission]
    let version: Int64
}
nonisolated struct AssignHouseholdRoleRequest: Encodable, Equatable, Sendable {
    let roleId: UUID
    let memberVersion: Int64
    let roleVersion: Int64
}
