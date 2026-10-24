import Foundation

nonisolated enum ChoreRecurrenceUnit: String, Codable, CaseIterable, Sendable {
    case hour
    case day
    case week
    case month
    case year

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
