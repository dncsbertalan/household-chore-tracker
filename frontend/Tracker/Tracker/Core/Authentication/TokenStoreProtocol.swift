//
//  TokenStoreProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

protocol TokenStoreProtocol: Sendable {
    func save(_ tokens: AuthTokens) async throws
    func load() async throws -> AuthTokens?
    func clear() async throws
}
