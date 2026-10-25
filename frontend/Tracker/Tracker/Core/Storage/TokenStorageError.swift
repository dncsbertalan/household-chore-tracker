import Foundation
import Security

nonisolated enum TokenStorageError: Error, LocalizedError, Sendable {
    case keychain(OSStatus)
    case invalidData

    var errorDescription: String? {
        AppLocalization.string("storage.error.secureTokens")
    }
}
