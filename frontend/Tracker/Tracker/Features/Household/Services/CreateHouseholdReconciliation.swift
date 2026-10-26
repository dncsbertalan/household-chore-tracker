import Foundation
import SwiftData

@MainActor
struct CreateHouseholdReconciliation: OutboxReconciliationProtocol {
    let response: HouseholdResponse
    let joinedAt: Date

    func apply(in context: ModelContext) throws {
        let id = response.householdId
        guard
            let household = try context.fetch(
                FetchDescriptor<LocalHousehold>(
                    predicate: #Predicate { $0.householdId == id }
                )
            ).first, household.createdByUserId == response.createdByUserId
        else {
            throw OutboxError.missingEntity
        }
        // Validate the complete graph before applying anything.
        guard household.householdRoles.count == response.roles.count,
            response.roles.allSatisfy({ role in
                household.householdRoles.contains {
                    $0.householdRoleId == role.householdRoleId
                }
            }),
            let member = household.householdMembers.first(where: {
                $0.householdMemberId
                    == response.creatorMembership.householdMemberId
            }), member.userId == response.creatorMembership.userId,
            let creatorRole = household.householdRoles.first(where: {
                $0.householdRoleId
                    == response.creatorMembership.householdRole.householdRoleId
            })
        else { throw OutboxError.missingEntity }

        if household.localRevision == 1 {
            household.name = response.name
            household.householdDescription = response.description
            household.markSynced(serverVersion: response.version)
        } else {
            household.serverVersion = response.version
        }
        for roleResponse in response.roles {
            guard
                let role = household.householdRoles.first(where: {
                    $0.householdRoleId == roleResponse.householdRoleId
                })
            else { throw OutboxError.missingEntity }
            if role.localRevision == 1 {
                role.name = roleResponse.name
                role.permissions = roleResponse.permissions.map(\.name)
                role.isSystemRole = roleResponse.isSystemRole
                role.markSynced(serverVersion: roleResponse.version)
            } else {
                role.serverVersion = roleResponse.version
            }
        }
        if member.localRevision == 1 {
            member.nickname = response.creatorMembership.nickname
            member.joinedAt = joinedAt
            member.role = creatorRole
            member.markSynced(serverVersion: response.creatorMembership.version)
        } else {
            member.serverVersion = response.creatorMembership.version
        }
    }
}
