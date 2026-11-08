//
//  KeychainTokenStore.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

actor KeychainTokenStore: TokenStoreProtocol {
    static let shared = KeychainTokenStore()

    private let key = "auth.tokens"

    func save(_ tokens: StoredTokens) async throws {
        try KeychainManager.save(tokens, forKey: key)
    }

    func load() async throws -> StoredTokens? {
        try KeychainManager.load(StoredTokens.self, forKey: key)
    }

    func clear() async throws {
        try KeychainManager.delete(forKey: key)
    }
}
