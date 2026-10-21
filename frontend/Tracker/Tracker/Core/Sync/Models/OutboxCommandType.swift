/// Stable command names shared by producers and the outbox. Persisted raw values must not change.
nonisolated enum OutboxCommandType: String, Codable, Sendable {
    case createHousehold = "household.create"
}
