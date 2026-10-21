import Foundation
import SwiftData

@MainActor
struct LocalHouseholdRepository: HouseholdRepositoryProtocol {
    static let schema = TrackerSchema.schema
    let container: ModelContainer

    func create(_ creation: HouseholdCreation) throws {
        let name = HouseholdConstraints.normalizedName(creation.name)
        let description = HouseholdConstraints.normalizedName(creation.description)
        let roleName = HouseholdConstraints.normalizedName(creation.roleName)
        guard HouseholdConstraints.isValidName(name),
              description.utf16.count <= HouseholdConstraints.descriptionMaxLength else {
            throw LocalHouseholdStoreError.invalidDetails
        }
        guard HouseholdConstraints.isValidRoleName(roleName) else {
            throw LocalHouseholdStoreError.invalidRole
        }

        // Keep this transaction separate from unrelated edits in the UI's context.
        let context = ModelContext(container)
        context.autosaveEnabled = false

        // SwiftData's unique attributes upsert, so reject an existing role ID explicitly.
        let roleId = creation.creatorRoleId
        guard try context.fetchCount(FetchDescriptor<LocalHouseholdRole>(
            predicate: #Predicate { $0.householdRoleId == roleId }
        )) == 0 else {
            throw LocalHouseholdStoreError.duplicateID
        }

        let household = LocalHousehold(
            householdId: UUID(), name: name,
            householdDescription: description.isEmpty ? nil : description,
            createdByUserId: creation.creatorUserId,
            localRevision: 1, status: .pending,
            householdRoles: [], householdMembers: []
        )
        context.insert(household)

        let role = LocalHouseholdRole(
            householdRoleId: roleId, name: roleName,
            permissions: HouseholdPermission.allCases.filter { creation.permissions.contains($0) },
            household: household, isSystemRole: false, members: []
        )
        context.insert(role)

        let member = LocalHouseholdMember(
            householdMemberId: UUID(), userId: creation.creatorUserId,
            joinedAt: Date(), household: household, role: role,
            localRevision: 1, status: .pending
        )
        context.insert(member)
        household.householdRoles = [role]
        household.householdMembers = [member]
        role.members = [member]

        ///TODO: Insert the household creation outbox record in this context before saving,
        /// using these same household, role, and membership IDs so it commits with the graph.
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        ///TODO: Notify the sync coordinator after the graph and its future outbox record commit.
    }
}

nonisolated enum LocalHouseholdStoreError: Error {
    case duplicateID
    case invalidDetails
    case invalidRole
}
