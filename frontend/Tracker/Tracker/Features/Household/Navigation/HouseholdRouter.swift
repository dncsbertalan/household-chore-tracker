//
//  ProfileRouter.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

enum WelcomeRoute: Hashable {
    case login
    case register
}

enum WelcomeSheet: String, Identifiable {
    case forgotPassword

    var id: String { rawValue }
}

typealias WelcomeRouter = Router<WelcomeRoute, WelcomeSheet>
