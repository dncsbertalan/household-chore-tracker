enum OutboxStatus: String, Codable, Sendable {
    /// Ready for transmission or waiting for retry.
    case pending
    /// Cannot proceed automatically, perhaps because of an unresolved conflict.
    case blocked
}
