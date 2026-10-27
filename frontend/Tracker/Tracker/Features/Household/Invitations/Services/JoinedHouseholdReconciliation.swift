import Foundation
import SwiftData

/// Applied by OutboxQueue in the same save that removes the acceptance command.
@MainActor
struct JoinedHouseholdReconciliation: OutboxReconciliationProtocol {
    let response: JoinedHouseholdResponse
    let joinedAt: Date

    func apply(in context: ModelContext) throws {
        let id = response.householdId
        let storedHousehold = try context.fetch(FetchDescriptor<LocalHousehold>(
            predicate: #Predicate { $0.householdId == id }
        )).first
        if let storedHousehold {
            guard storedHousehold.createdByUserId == response.createdByUserId,
                  storedHousehold.deletedAt == nil else { throw OutboxError.invalidResponse }
        }

        // Preflight IDs before inserting: SwiftData's unique attributes otherwise upsert silently.
        var storedRoles: [UUID: LocalHouseholdRole] = [:]
        for role in response.roles {
            let roleId = role.householdRoleId
            if let existing = try context.fetch(FetchDescriptor<LocalHouseholdRole>(
                predicate: #Predicate { $0.householdRoleId == roleId }
            )).first {
                guard existing.household.householdId == id, existing.deletedAt == nil else {
                    throw OutboxError.invalidResponse
                }
                storedRoles[roleId] = existing
            }
        }
        let memberResponse = response.membership
        let memberId = memberResponse.householdMemberId
        let storedMember = try context.fetch(FetchDescriptor<LocalHouseholdMember>(
            predicate: #Predicate { $0.householdMemberId == memberId }
        )).first
        if let storedMember {
            guard storedMember.household.householdId == id, storedMember.userId == memberResponse.userId,
                  storedMember.deletedAt == nil else { throw OutboxError.invalidResponse }
        }
        guard storedHousehold?.householdMembers.contains(where: {
            $0.userId == memberResponse.userId && $0.householdMemberId != memberId
        }) != true else { throw OutboxError.invalidResponse }

        let household: LocalHousehold
        if let existing = storedHousehold {
            household = existing
            if existing.status == .synced && response.version >= (existing.serverVersion ?? 0) {
                household.name = response.name
                household.householdDescription = response.description
                household.markSynced(serverVersion: response.version)
            }
            household.serverVersion = max(household.serverVersion ?? 0, response.version)
        } else {
            household = LocalHousehold(householdId: id, name: response.name, householdDescription: response.description,
                                       createdByUserId: response.createdByUserId, serverVersion: response.version,
                                       localRevision: 1, status: .synced, lastSyncedAt: .now,
                                       householdRoles: [], householdMembers: [])
            context.insert(household)
        }

        var importedRoles: [UUID: LocalHouseholdRole] = [:]
        for roleResponse in response.roles {
            let role: LocalHouseholdRole
            if let existing = storedRoles[roleResponse.householdRoleId] {
                role = existing
                if existing.status == .synced && roleResponse.version >= (existing.serverVersion ?? 0) {
                    role.name = roleResponse.name
                    role.permissions = roleResponse.permissions.map(\.name)
                    role.isSystemRole = roleResponse.isSystemRole
                    role.markSynced(serverVersion: roleResponse.version)
                }
                role.serverVersion = max(role.serverVersion ?? 0, roleResponse.version)
            } else {
                role = LocalHouseholdRole(householdRoleId: roleResponse.householdRoleId, name: roleResponse.name,
                                           permissions: roleResponse.permissions.map(\.name), household: household,
                                           isSystemRole: roleResponse.isSystemRole, members: [])
                role.markSynced(serverVersion: roleResponse.version)
                context.insert(role)
            }
            importedRoles[roleResponse.householdRoleId] = role
        }
        guard let memberRole = importedRoles[memberResponse.householdRole.householdRoleId] else {
            throw OutboxError.invalidResponse
        }
        if let member = storedMember {
            if member.status == .synced && memberResponse.version >= (member.serverVersion ?? 0) {
                member.role = memberRole
                member.nickname = memberResponse.nickname
                member.joinedAt = joinedAt
                member.markSynced(serverVersion: memberResponse.version)
            }
            member.serverVersion = max(member.serverVersion ?? 0, memberResponse.version)
        } else {
            let member = LocalHouseholdMember(householdMemberId: memberId, userId: memberResponse.userId,
                                              nickname: memberResponse.nickname, joinedAt: joinedAt,
                                              household: household, role: memberRole, localRevision: 1, status: .synced)
            member.markSynced(serverVersion: memberResponse.version)
            context.insert(member)
        }
    }
}
