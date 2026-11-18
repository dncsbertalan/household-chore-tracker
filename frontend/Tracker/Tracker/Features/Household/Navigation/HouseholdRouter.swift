//
//  ProfileRouter.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import Foundation

enum HouseholdRoute: Hashable {
    case invitations
    case householdDetail(_ householdId: UUID)
}

enum HouseholdSheet: String, Identifiable {
    case createHousehold

    var id: String { rawValue }
}

typealias HouseholdRouter = Router<HouseholdRoute, HouseholdSheet>
