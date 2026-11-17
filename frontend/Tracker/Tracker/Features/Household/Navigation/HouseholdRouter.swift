//
//  ProfileRouter.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

enum HouseholdRoute: Hashable {
    case main
}

enum HouseholdSheet: String, Identifiable {
    case createHousehold

    var id: String { rawValue }
}

typealias HouseholdRouter = Router<HouseholdRoute, HouseholdSheet>
