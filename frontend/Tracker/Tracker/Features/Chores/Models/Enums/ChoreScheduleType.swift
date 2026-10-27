nonisolated enum ChoreScheduleType: String, Codable, CaseIterable, Sendable {
    case fixed = "FIXED"
    case afterCompletion = "AFTER_COMPLETION"
    case onDemand = "ON_DEMAND"

    init(from decoder: any Decoder) throws {
        self = try ChoreEnumCoding.decode(Self.self, from: decoder)
    }
}
