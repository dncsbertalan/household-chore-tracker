import Foundation

nonisolated enum SessionError: Error, LocalizedError, Sendable {
    case signInRequired
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .signInRequired:
            return AppLocalization.string("auth.error.signInRequired")
        case .sessionExpired:
            return AppLocalization.string("auth.error.sessionExpired")
        }
    }
}
