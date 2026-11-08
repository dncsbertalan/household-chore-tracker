//
//  TokenStoreProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

nonisolated protocol TokenStoreProtocol: Sendable {
    func save(_ tokens: StoredTokens) async throws
    func load() async throws -> StoredTokens?
    func clear() async throws
}
