import Foundation
import Observation

@MainActor
@Observable
final class EditChoreViewModel {
    let original: ChoreResponse
    var title: String
    var description: String
    var pattern: ChoreCreationPattern {
        didSet {
            if pattern == .fixed && original.occurrence == nil {
                hasScheduledTime = true
                scheduledAt = startsAt
            }
        }
    }
    var recurrenceUnit: ChoreRecurrenceUnit
    var recurrenceInterval: Int
    var startsAt: Date
    var hasScheduledTime: Bool
    var scheduledAt: Date
    var hasDeadline: Bool
    var dueAt: Date
    var timeZoneIdentifier: String
    var assignedMemberIds: Set<UUID>
    var requiresApproval: Bool
    var requiredApprovalCount: Int
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var needsReload = false
    private var attempt: (request: UpdateChoreRequest, id: UUID)?

    init(chore: ChoreResponse) {
        original = chore
        title = chore.title
        description = chore.description ?? ""
        pattern = chore.pattern
        recurrenceUnit = chore.schedule?.recurrenceUnit ?? .day
        recurrenceInterval = chore.schedule?.recurrenceInterval ?? 1
        startsAt = ChoreTimestamp.decode(chore.schedule?.startsAt) ?? ChoreTimestamp.decode(chore.occurrence?.scheduledAt) ?? .now
        hasScheduledTime = chore.occurrence?.scheduledAt != nil
        scheduledAt = ChoreTimestamp.decode(chore.occurrence?.scheduledAt) ?? ChoreTimestamp.decode(chore.schedule?.startsAt) ?? .now
        hasDeadline = chore.occurrence?.dueAt != nil
        dueAt = ChoreTimestamp.decode(chore.occurrence?.dueAt) ?? .now.addingTimeInterval(86_400)
        timeZoneIdentifier = chore.schedule?.timeZoneIdentifier ?? TimeZone.current.identifier
        assignedMemberIds = Set(chore.assignedMemberIds)
        requiresApproval = chore.requiredApprovalCount > 0
        requiredApprovalCount = max(1, chore.requiredApprovalCount)
    }

    var hasOccurrence: Bool { original.occurrence != nil || pattern != .onDemand }
    var requiresScheduledTime: Bool { original.occurrence == nil && pattern == .fixed }
    var isRecurring: Bool { pattern == .fixed || pattern == .afterCompletion }
    var canSave: Bool {
        original.isEditable && !isSaving && !needsReload
            && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && title.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count <= ChoreCreation.titleMaxLength
            && description.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count <= ChoreCreation.descriptionMaxLength
            && recurrenceInterval > 0 && TimeZone(identifier: timeZoneIdentifier) != nil
            && (!hasOccurrence || !(hasScheduledTime || requiresScheduledTime) || !hasDeadline || dueAt >= scheduledAt)
            && (!requiresApproval || requiredApprovalCount > 0)
    }

    var request: UpdateChoreRequest {
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return UpdateChoreRequest(version: original.version, scheduleVersion: original.schedule?.version,
            occurrenceId: original.occurrence?.id, occurrenceVersion: original.occurrence?.version,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines), description: description.isEmpty ? nil : description,
            pattern: pattern, recurrenceUnit: isRecurring ? recurrenceUnit : nil,
            recurrenceInterval: isRecurring ? recurrenceInterval : 1,
            startsAt: pattern == .fixed ? timestamp(startsAt, preserving: original.schedule?.startsAt)
                : (pattern == .afterCompletion && original.pattern == .afterCompletion ? original.schedule?.startsAt : nil),
            scheduledAt: hasOccurrence && (hasScheduledTime || requiresScheduledTime) ? timestamp(scheduledAt, preserving: original.occurrence?.scheduledAt) : nil,
            dueAt: hasOccurrence && hasDeadline ? timestamp(dueAt, preserving: original.occurrence?.dueAt) : nil,
            timeZoneIdentifier: timeZoneIdentifier,
            assignedMemberIds: assignedMemberIds.sorted { $0.uuidString < $1.uuidString },
            requiredApprovalCount: requiresApproval ? requiredApprovalCount : 0)
    }

    private func timestamp(_ date: Date, preserving original: String?) -> String? {
        if let original, ChoreTimestamp.decode(original) == date { return original }
        return ChoreTimestamp.encode(date)
    }

    func save(accountId: UUID, using repository: any ChoreRepositoryProtocol) async -> ChoreResponse? {
        guard canSave else { return nil }
        let request = request
        if attempt?.request != request { attempt = (request, UUID()) }
        guard let attempt else { return nil }
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            return try await repository.update(id: original.id, accountId: accountId, request: request, requestId: attempt.id)
        } catch is CancellationError { return nil }
        catch APIError.http(let status, _) where status == 409 {
            needsReload = true
            errorMessage = AppLocalization.string("chores.edit.conflict")
        } catch APIError.http(let status, _) where status == 403 {
            errorMessage = AppLocalization.string("chores.edit.permission")
        } catch { errorMessage = error.localizedDescription }
        return nil
    }
}
