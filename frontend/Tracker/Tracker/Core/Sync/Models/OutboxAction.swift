nonisolated enum OutboxAction: String, Codable, Sendable {
    case create
    case update
    case delete
    case complete
    case accept
    case decline
    case revoke
}
