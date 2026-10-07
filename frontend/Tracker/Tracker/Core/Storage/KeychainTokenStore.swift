import Foundation
import Security

nonisolated protocol TokenStoring: Sendable {
    func save(_ tokens: StoredTokens) async throws
    func load() async throws -> StoredTokens?
    func clear() async throws
    func replace(_ tokens: StoredTokens, ifMatching expected: StoredTokens) async throws -> Bool
    func clear(ifMatching expected: StoredTokens) async throws -> Bool
}

nonisolated enum TokenStorageError: Error, LocalizedError, Sendable {
    case keychain(OSStatus)
    case invalidData

    var errorDescription: String? {
        String(localized: "storage.error.secureTokens")
    }
}

actor KeychainTokenStore: TokenStoring {
    private let service: String
    private let account = "authentication-tokens"

    init(service: String) {
        self.service = service
    }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account,
         kSecAttrSynchronizable as String: false]
    }

    func save(_ tokens: StoredTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        // Update in place: never delete an existing pair before its replacement is saved.
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let item = query.merging(attributes) { _, new in new }
            let added = SecItemAdd(item as CFDictionary, nil)
            guard added == errSecSuccess else { throw TokenStorageError.keychain(added) }
        } else if status != errSecSuccess {
            throw TokenStorageError.keychain(status)
        }
    }

    func load() throws -> StoredTokens? {
        var search = query
        search[kSecReturnData as String] = true
        search[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(search as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw TokenStorageError.keychain(status) }
        guard let data = result as? Data,
              let tokens = try? JSONDecoder().decode(StoredTokens.self, from: data) else {
            throw TokenStorageError.invalidData
        }
        return tokens
    }

    // Compare and mutate without an actor suspension, so an old refresh cannot overwrite a login.
    func replace(_ tokens: StoredTokens, ifMatching expected: StoredTokens) throws -> Bool {
        guard try load() == expected else { return false }
        try save(tokens)
        return true
    }

    func clear(ifMatching expected: StoredTokens) throws -> Bool {
        guard try load() == expected else { return false }
        try clear()
        return true
    }

    func clear() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStorageError.keychain(status)
        }
    }
}
