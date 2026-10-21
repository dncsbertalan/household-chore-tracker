import Foundation

/// Stable, bounded diagnostics. Never persist raw errors, server bodies, credentials, or request payloads here.
nonisolated enum SyncFailureCategory: String, Sendable {
    case authentication, network, server, requestRejected, invalidCommand, invalidResponse, localData, storage, unknown
}

nonisolated struct SyncFailureSummary: Equatable, Sendable {
    let disposition: SyncFailureDisposition
    let category: SyncFailureCategory
    let httpStatus: Int?

    init(disposition: SyncFailureDisposition, category: SyncFailureCategory, httpStatus: Int? = nil) {
        self.disposition = disposition
        self.category = category
        self.httpStatus = httpStatus
    }

    init(error: any Error) {
        disposition = SyncFailureDisposition.classify(error)
        var status: Int?
        if disposition == .authenticationRequired {
            category = .authentication
            if case APIError.http(let code, _) = error { status = code }
        } else if let api = error as? APIError {
            switch api {
            case .transport: category = .network
            case .http(let code, _):
                status = code
                category = code >= 500 ? .server : .requestRejected
            case .invalidResponse, .decodingFailed: category = .invalidResponse
            default: category = .invalidCommand
            }
        } else if let sync = error as? OutboxSyncError {
            switch sync {
            case .invalidPayload, .unsupportedPayloadVersion: category = .invalidCommand
            case .invalidResponse: category = .invalidResponse
            default: category = .localData
            }
        } else if error is OutboxRecordError {
            category = .invalidCommand
        } else if (error as NSError).domain == NSCocoaErrorDomain {
            category = .storage
        } else {
            category = .unknown
        }
        httpStatus = status
    }
}

/// Failed queue runs for one authenticated account, matching the coordinator's existing retry scope.
nonisolated struct SyncRetryCheckpoint: Equatable, Sendable {
    let accountId: UUID
    let failedAttempts: Int
    let lastFailureAt: Date
    let failure: SyncFailureSummary
    let nextRetryAt: Date?
}

/// After relaunch only the safe summary is restored, never an arbitrary serialized Error.
nonisolated struct StoredSyncFailure: Error, Equatable, Sendable {
    let summary: SyncFailureSummary
}
