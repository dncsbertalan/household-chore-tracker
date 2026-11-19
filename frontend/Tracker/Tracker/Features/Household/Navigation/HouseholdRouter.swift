//
//  ProfileRouter.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import Foundation

enum HouseholdRoute: Hashable {
    case createChore(household: HouseholdResponse)
    case choreDetail(_ choreId: UUID)
    case householdRoles(_ householdId: UUID)
    case invitations
    case householdDetail(_ householdId: UUID)
    case householdMemberDetails(_ member: HouseholdMemberResponse, isCurrentUser: Bool)
}

enum HouseholdSheet: Identifiable, Equatable {
    case createHousehold
    case createHouseholdInvitation(household: HouseholdResponse)

    var id: String {
        switch self {
        case .createHousehold:
            return "createHousehold"

        case .createHouseholdInvitation(let household):
            return "createHouseholdInvitation-\(household.id)"
        }
    }
}

typealias HouseholdRouter = Router<HouseholdRoute, HouseholdSheet>
