//
//  KeychainError.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation
import Security

enum KeychainError: LocalizedError {
    case unexpectedData
    case unhandledError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedData:
            return "The Keychain returned invalid data."
        case .unhandledError(let status):
            let message = SecCopyErrorMessageString(status, nil)
            return (message as String?) ?? "Keychain error: \(status)"
        }
    }
}
