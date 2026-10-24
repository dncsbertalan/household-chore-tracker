/// Uses Foundation Calendar's weekday numbering.
nonisolated enum ChoreWeekday: Int, Codable, CaseIterable, Sendable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}
