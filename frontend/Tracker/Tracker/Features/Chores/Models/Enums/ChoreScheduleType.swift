nonisolated enum ChoreScheduleType: String, Codable, CaseIterable, Sendable {
    case fixed = "FIXED"
    case afterCompletion = "AFTER_COMPLETION"
    case onDemand = "ON_DEMAND"

}
