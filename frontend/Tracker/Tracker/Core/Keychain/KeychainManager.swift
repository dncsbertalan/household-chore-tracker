//
//  KeychainManager.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation
import Security

nonisolated enum KeychainManager {
    private static let service = Bundle.main.bundleIdentifier ?? "Tracker"

    private static func query(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: false
        ]
    }

    static func save(_ data: Data, forKey key: String) throws {
        let query = query(forKey: key)

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainError.unhandledError(updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] =
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(
            addQuery as CFDictionary,
            nil
        )

        guard addStatus == errSecSuccess else {
            throw KeychainError.unhandledError(addStatus)
        }
    }

    static func load(forKey key: String) throws -> Data? {
        var query = query(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }

        return data
    }

    static func delete(forKey key: String) throws {
        let status = SecItemDelete(
            query(forKey: key) as CFDictionary
        )

        guard status == errSecSuccess ||
              status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status)
        }
    }

    static func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        try save(data, forKey: key)
    }

    static func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try load(forKey: key) else {
            return nil
        }

        return try JSONDecoder().decode(type, from: data)
    }
}
