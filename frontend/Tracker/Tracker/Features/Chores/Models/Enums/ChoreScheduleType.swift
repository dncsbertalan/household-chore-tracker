nonisolated enum ChoreScheduleType: String, Codable, CaseIterable, Sendable {
    case fixed
    case afterCompletion
    case onDemand
}
