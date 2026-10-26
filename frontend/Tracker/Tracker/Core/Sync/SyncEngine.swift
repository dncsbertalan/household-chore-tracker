import Foundation

/// One worker task serializes delivery across foreground, connectivity and new-command triggers.
@MainActor
final class SyncEngine {
    private let queue: OutboxQueue
    private let dispatcher: OutboxDispatcher
    private let currentUserService: any CurrentUserServiceProtocol
    private var workerTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var sessionGeneration = UUID()
    private var isSyncRequested = false
    private var isEnabled = false
    private(set) var lastError: String?

    init(
        queue: OutboxQueue,
        dispatcher: OutboxDispatcher,
        currentUserService: any CurrentUserServiceProtocol
    ) {
        self.queue = queue
        self.dispatcher = dispatcher
        self.currentUserService = currentUserService
    }

    func start() {
        isEnabled = true
        requestSync()
    }

    func stop() {
        isEnabled = false
        sessionGeneration = UUID()
        workerTask?.cancel()
        retryTask?.cancel()
        retryTask = nil
        // Keep the worker task until it exits: a new session must not overlap its request.
    }

    func requestSync() {
        guard isEnabled else { return }
        isSyncRequested = true
        retryTask?.cancel()
        retryTask = nil
        guard workerTask == nil else { return }
        let sessionGeneration = sessionGeneration
        workerTask = Task { [weak self] in
            guard let self else { return }
            await run(sessionGeneration: sessionGeneration)
            workerTask = nil
            if isEnabled && isSyncRequested { requestSync() }
        }
    }

    private func run(sessionGeneration: UUID) async {
        while isEnabled && self.sessionGeneration == sessionGeneration
            && !Task.isCancelled
        {
            isSyncRequested = false
            do {
                // Resolve the account from authenticated /users/me, never from an outbox record.
                let accountId = try await currentUserService.fetchCurrentUser()
                    .id
                try Task.checkCancellation()
                guard self.sessionGeneration == sessionGeneration else {
                    return
                }
                while let operation = try queue.next(accountId: accountId) {
                    try Task.checkCancellation()
                    do {
                        let reconciliation = try await dispatcher.send(
                            operation
                        )
                        try Task.checkCancellation()
                        guard self.sessionGeneration == sessionGeneration else {
                            return
                        }
                        try queue.acknowledge(
                            id: operation.id,
                            applying: reconciliation
                        )
                        lastError = nil
                    } catch {
                        try Task.checkCancellation()
                        if error is SessionError { throw error }
                        if shouldBlock(error) {
                            try queue.block(
                                id: operation.id,
                                reason: error.localizedDescription
                            )
                        } else {
                            try queue.scheduleRetry(
                                id: operation.id,
                                error: error.localizedDescription
                            )
                        }
                        lastError = error.localizedDescription
                        break
                    }
                }
                if isSyncRequested { continue }
                guard let next = try queue.nextAttemptAt(accountId: accountId)
                else { return }
                scheduleRetry(
                    after: max(0.1, next.timeIntervalSinceNow),
                    sessionGeneration: sessionGeneration
                )
                return
            } catch is CancellationError {
                return
            } catch let error as SessionError {
                // An old account lookup must not consume a newer session's pending trigger.
                if self.sessionGeneration == sessionGeneration
                    && !Task.isCancelled
                {
                    lastError = error.localizedDescription
                    isSyncRequested = false
                }
                return
            } catch {
                guard isEnabled, self.sessionGeneration == sessionGeneration,
                    !Task.isCancelled
                else { return }
                lastError = error.localizedDescription
                // Also retry failures resolving the authenticated account or saving queue state.
                scheduleRetry(after: 30, sessionGeneration: sessionGeneration)
                return
            }
        }
    }

    private func scheduleRetry(
        after delay: TimeInterval,
        sessionGeneration: UUID
    ) {
        retryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            guard let self, self.sessionGeneration == sessionGeneration else {
                return
            }
            requestSync()
        }
    }

    private func shouldBlock(_ error: Error) -> Bool {
        if case APIError.http(let status, _) = error {
            return (400...499).contains(status)
                && ![401, 408, 429].contains(status)
        }
        if let error = error as? APIError {
            switch error {
            case .invalidConfiguration, .invalidEndpoint, .encodingFailed,
                .decodingFailed:
                return true
            default: break
            }
        }
        return error is OutboxError || error is DecodingError
    }
}
