import Foundation

nonisolated enum ChoreRecurrenceUnit: String, Codable, CaseIterable, Sendable {
    case hour = "HOUR"
    case day = "DAY"
    case week = "WEEK"
    case month = "MONTH"
    case year = "YEAR"

    init(from decoder: any Decoder) throws {
        self = try ChoreEnumCoding.decode(Self.self, from: decoder)
    }

    var title: String {
        switch self {
        case .hour: AppLocalization.string("chores.recurrence.hour")
        case .day: AppLocalization.string("chores.recurrence.day")
        case .week: AppLocalization.string("chores.recurrence.week")
        case .month: AppLocalization.string("chores.recurrence.month")
        case .year: AppLocalization.string("chores.recurrence.year")
        }
    }
}
