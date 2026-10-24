import Foundation
import SwiftData

/// A chore without a schedule is a one-off chore.
@Model
final class LocalChoreSchedule: SyncableEntity {
    @Attribute(.unique) var choreScheduleId: UUID
    var scheduleType: ChoreScheduleType
    /// Used by fixed and after-completion schedules; absent for on-demand chores.
    var recurrenceUnit: ChoreRecurrenceUnit?
    var recurrenceInterval: Int
    /// Optional filters for fixed weekly/monthly schedules.
    var weekdays: [ChoreWeekday]
    var daysOfMonth: [Int]
    /// The anchor also supplies the time of day for fixed schedules.
    var startsAt: Date?
    var endsAt: Date?
    var timeZoneIdentifier: String

    var chore: LocalChore

    var deletedAt: Date?
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?

    init(choreScheduleId: UUID = UUID(), chore: LocalChore, scheduleType: ChoreScheduleType,
         recurrenceUnit: ChoreRecurrenceUnit? = nil, recurrenceInterval: Int = 1,
         weekdays: [ChoreWeekday] = [], daysOfMonth: [Int] = [],
         startsAt: Date? = nil, endsAt: Date? = nil,
         timeZoneIdentifier: String = TimeZone.current.identifier) {
        self.choreScheduleId = choreScheduleId
        self.chore = chore
        self.scheduleType = scheduleType
        self.recurrenceUnit = recurrenceUnit
        self.recurrenceInterval = recurrenceInterval
        self.weekdays = weekdays
        self.daysOfMonth = daysOfMonth
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.timeZoneIdentifier = timeZoneIdentifier
    }
}
