//
//  PreviewCurrentUserRepository.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import Foundation

struct PreviewCurrentUserRepository: CurrentUserRepositoryProtocol {

    func getCurrentUser() async throws -> CurrentUser {
        CurrentUser(
            id: UUID(),
            email: "alex.morgan@example.com",
            firstName: "Alex",
            lastName: "Morgan"
        )
    }
}
