import Foundation
import SwiftData

@MainActor
struct LocalHouseholdRepository: HouseholdRepositoryProtocol {
    static let schema = AppSchema.schema
    let container: ModelContainer

    func create(_ creation: HouseholdCreation) throws {
        let name = HouseholdConstraints.trimmedText(creation.name)
        let description = HouseholdConstraints.trimmedText(
            creation.description
        )
        let roleName = HouseholdConstraints.trimmedText(creation.roleName)
        guard HouseholdConstraints.isValidName(name),
            description.utf16.count <= HouseholdConstraints.descriptionMaxLength
        else {
            throw LocalHouseholdRepositoryError.invalidDetails
        }
        guard HouseholdConstraints.isValidRoleName(roleName) else {
            throw LocalHouseholdRepositoryError.invalidRole
        }

        // Keep this transaction separate from unrelated edits in the UI's context.
        let context = ModelContext(container)
        context.autosaveEnabled = false

        // SwiftData's unique attributes upsert, so reject an existing role ID explicitly.
        let roleId = creation.creatorRoleId
        guard
            try context.fetchCount(
                FetchDescriptor<LocalHouseholdRole>(
                    predicate: #Predicate { $0.householdRoleId == roleId }
                )
            ) == 0
        else {
            throw LocalHouseholdRepositoryError.duplicateID
        }

        let household = LocalHousehold(
            householdId: UUID(),
            name: name,
            householdDescription: description.isEmpty ? nil : description,
            createdByUserId: creation.creatorUserId,
            localRevision: 1,
            status: .pending,
            householdRoles: [],
            householdMembers: []
        )
        context.insert(household)

        let role = LocalHouseholdRole(
            householdRoleId: roleId,
            name: roleName,
            permissions: HouseholdPermission.allCases.filter {
                creation.permissions.contains($0)
            },
            household: household,
            isSystemRole: false,
            members: []
        )
        context.insert(role)

        let member = LocalHouseholdMember(
            householdMemberId: UUID(),
            userId: creation.creatorUserId,
            joinedAt: Date(),
            household: household,
            role: role,
            localRevision: 1,
            status: .pending
        )
        context.insert(member)
        household.householdRoles = [role]
        household.householdMembers = [member]
        role.members = [member]

        do {
            let request = CreateHouseholdRequest(
                householdId: household.householdId, name: household.name,
                description: household.householdDescription,
                roles: [CreateHouseholdRequest.Role(
                    householdRoleId: role.householdRoleId, name: role.name, permissions: role.permissions
                )],
                creatorRoleId: role.householdRoleId, householdMemberId: member.householdMemberId
            )
            try OutboxStore.enqueue(OutboxOperation(
                accountId: creation.creatorUserId, entityType: .household,
                entityId: household.householdId, action: .create, payload: request
            ), in: context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        NotificationCenter.default.post(name: .outboxDidEnqueue, object: nil)
    }
}
