import Foundation
import Observation

@MainActor
@Observable
final class CreateChoreViewModel {
    private let householdId: UUID
    private let userId: UUID
    private var lastAttempt: ChoreCreation?
    private let choreId = UUID()
    private let scheduleId = UUID()
    private let occurrenceId = UUID()
    private(set) var isSaving = false

    var title = ""
    var description = ""
    var pattern: ChoreCreationPattern = .once
    var recurrenceUnit: ChoreRecurrenceUnit = .day
    var recurrenceInterval = 1
    var hasScheduledTime = false
    var scheduledAt = Date.now
    var hasDeadline = false
    var dueAt = Date.now.addingTimeInterval(86_400)
    var selectedMemberIds: Set<UUID> = []
    var requiresApproval = false
    var requiredApprovalCount = 1
    private(set) var errorMessage: String?
    private(set) var didSave = false

    init(householdId: UUID, userId: UUID) {
        self.householdId = householdId
        self.userId = userId
    }

    var canContinueWithDetails: Bool { creation.hasValidDetails }
    var canContinueWithSchedule: Bool { creation.hasValidSchedule }

    func canCreate(availableMemberIds: Set<UUID>) -> Bool {
        canContinueWithDetails && canContinueWithSchedule && !didSave && !isSaving
            && selectedMemberIds.isSubset(of: availableMemberIds)
            && (!requiresApproval || (requiredApprovalCount > 0
                && requiredApprovalCount <= availableMemberIds.count))
    }

    private var creation: ChoreCreation {
        ChoreCreation(
            scheduleId: scheduleId, occurrenceId: occurrenceId,
            choreId: choreId, householdId: householdId, createdByUserId: userId,
            title: title, description: description, pattern: pattern,
            recurrenceUnit: recurrenceUnit, recurrenceInterval: recurrenceInterval,
            scheduledAt: pattern != .onDemand && (pattern == .fixed || hasScheduledTime) ? scheduledAt : nil,
            dueAt: pattern != .onDemand && hasDeadline ? dueAt : nil,
            timeZoneIdentifier: TimeZone.current.identifier,
            assignedMemberIds: selectedMemberIds.sorted { $0.uuidString < $1.uuidString },
            requiredApprovalCount: requiresApproval ? requiredApprovalCount : 0
        )
    }

    func create(using repository: any ChoreRepositoryProtocol) async {
        guard !didSave, !isSaving else { return }
        errorMessage = nil
        guard canContinueWithDetails else {
            errorMessage = AppLocalization.string("chores.error.details")
            return
        }
        guard canContinueWithSchedule else {
            errorMessage = AppLocalization.string("chores.error.schedule")
            return
        }
        guard !requiresApproval || requiredApprovalCount > 0 else {
            errorMessage = AppLocalization.string("chores.error.members")
            return
        }
        isSaving = true
        defer { isSaving = false }
        var submitted = creation
        if let previous = lastAttempt {
            var candidate = submitted
            candidate.requestId = previous.requestId
            if candidate == previous { submitted = candidate }
        }
        lastAttempt = submitted
        do {
            _ = try await repository.create(submitted)
            didSave = true
        } catch HouseholdAuthorizationError.permissionDenied(_) {
            errorMessage = AppLocalization.string("chores.error.permission")
        } catch is CancellationError {
            return
        } catch {
            errorMessage = AppLocalization.string("chores.error.save")
        }
    }
}
