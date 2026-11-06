import Foundation

/// Shared error policy for persistence and presentation.
nonisolated enum HouseholdRoleFailure {
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError || (error as? URLError)?.code == .cancelled { return true }
        if case APIError.transport(.cancelled) = error { return true }
        return false
    }

    static func invalidatesSnapshot(_ error: Error) -> Bool {
        if error is SessionError { return true }
        if case APIError.http(let status, _) = error { return [401, 403, 404].contains(status) }
        return false
    }

    static func canUseCachedData(after error: Error) -> Bool {
        switch error {
        case APIError.transport(let code): return code != .cancelled
        case is URLError: return !isCancellation(error)
        case APIError.http(let status, _): return status >= 500 || status == 429
        default: return false
        }
    }

}
