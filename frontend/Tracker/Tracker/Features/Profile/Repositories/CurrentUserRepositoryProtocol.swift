//
//  CurrentUserRepositoryProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

nonisolated protocol CurrentUserRepositoryProtocol: Sendable {
    func getCurrentUser() async throws -> CurrentUser
}
