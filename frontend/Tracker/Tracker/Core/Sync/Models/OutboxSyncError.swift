nonisolated enum OutboxSyncError: Error, Equatable, Sendable {
    case alreadyRunning
    case accountMismatch
    case unsupportedPayloadVersion(Int)
    case invalidPayload
    case commandChanged
    case localStateChanged
    case invalidResponse
}
