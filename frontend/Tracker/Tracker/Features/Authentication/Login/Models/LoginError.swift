import Foundation

nonisolated enum LoginError: Error, LocalizedError {
    case alreadyInProgress
    var errorDescription: String? { AppLocalization.string("auth.error.alreadySigningIn") }
}
