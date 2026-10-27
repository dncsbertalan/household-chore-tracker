import Foundation

nonisolated enum ChoreCreationPattern: String, Codable, CaseIterable, Identifiable, Sendable {
    case once = "ONCE"
    case fixed = "FIXED"
    case afterCompletion = "AFTER_COMPLETION"
    case onDemand = "ON_DEMAND"

    init(from decoder: any Decoder) throws {
        self = try ChoreEnumCoding.decode(Self.self, from: decoder)
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .once: AppLocalization.string("chores.schedule.once")
        case .fixed: AppLocalization.string("chores.schedule.fixed")
        case .afterCompletion: AppLocalization.string("chores.schedule.afterCompletion")
        case .onDemand: AppLocalization.string("chores.schedule.onDemand")
        }
    }

    var scheduleType: ChoreScheduleType? {
        switch self {
        case .once: nil
        case .fixed: .fixed
        case .afterCompletion: .afterCompletion
        case .onDemand: .onDemand
        }
    }
}
