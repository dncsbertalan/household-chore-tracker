//
//  ProfileRouter.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import Observation
import SwiftUI

@Observable
final class ProfileRouter {
    var path = NavigationPath()
    var sheet: ProfileSheet?

    func navigate(to route: ProfileRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum ProfileRoute: Hashable {
    case main
}

enum ProfileSheet: Identifiable {
    case login
    case register

    var id: String {
        switch self {
        case .login: return "login"
        case .register: return "register"
        }
    }
}
