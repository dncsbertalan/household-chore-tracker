import Foundation
import SwiftData

@Model
final class SyncRetryRecord {
    @Attribute(.unique) private(set) var accountId: UUID
    private(set) var failedAttempts: Int
    private(set) var lastFailureAt: Date
    private(set) var disposition: String
    private(set) var category: String
    private(set) var httpStatus: Int?
    private(set) var nextRetryAt: Date?

    init(checkpoint: SyncRetryCheckpoint) {
        accountId = checkpoint.accountId
        failedAttempts = checkpoint.failedAttempts
        lastFailureAt = checkpoint.lastFailureAt
        disposition = checkpoint.failure.disposition.rawValue
        category = checkpoint.failure.category.rawValue
        httpStatus = checkpoint.failure.httpStatus
        nextRetryAt = checkpoint.nextRetryAt
    }

    func update(_ checkpoint: SyncRetryCheckpoint) {
        failedAttempts = checkpoint.failedAttempts
        lastFailureAt = checkpoint.lastFailureAt
        disposition = checkpoint.failure.disposition.rawValue
        category = checkpoint.failure.category.rawValue
        httpStatus = checkpoint.failure.httpStatus
        nextRetryAt = checkpoint.nextRetryAt
    }

    var checkpoint: SyncRetryCheckpoint {
        get throws {
            guard failedAttempts > 0,
                  let disposition = SyncFailureDisposition(rawValue: disposition),
                  let category = SyncFailureCategory(rawValue: category),
                  nextRetryAt == nil || disposition == .retryable else {
                throw SyncRetryStoreError.invalidCheckpoint
            }
            return SyncRetryCheckpoint(accountId: accountId, failedAttempts: failedAttempts,
                                       lastFailureAt: lastFailureAt,
                                       failure: SyncFailureSummary(disposition: disposition, category: category, httpStatus: httpStatus),
                                       nextRetryAt: nextRetryAt)
        }
    }
}

nonisolated enum SyncRetryStoreError: Error {
    case invalidCheckpoint
}
