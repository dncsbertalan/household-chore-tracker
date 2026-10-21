import Foundation

nonisolated enum SyncState: Equatable, Sendable {
    case inactive
    case waitingForNetwork
    case idle
    case running
    case waitingForRetry(attempt: Int, delay: Double)
    case waitingForTrigger
    case authenticationRequired
    case needsAttention
}

nonisolated enum SyncFailureDisposition: String, Equatable, Sendable {
    case retryable, authenticationRequired, needsAttention

    static func classify(_ error: any Error) -> Self {
        if error is SessionError { return .authenticationRequired }
        if case OutboxSyncError.accountMismatch = error { return .authenticationRequired }
        if let error = error as? APIError {
            switch error {
            case .transport(let code):
                switch code {
                case .timedOut, .notConnectedToInternet, .networkConnectionLost,
                     .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                    return .retryable
                default: return .needsAttention
                }
            case .http(let status, _):
                if status == 401 { return .authenticationRequired }
                return [408, 500, 502, 503, 504].contains(status) ? .retryable : .needsAttention
            default: return .needsAttention
            }
        }
        // Unknown persistence, payload and reconciliation failures require explicit handling.
        return .needsAttention
    }
}
