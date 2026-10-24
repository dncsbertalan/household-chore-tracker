import Foundation
import Observation

@MainActor
@Observable
final class CreateChoreViewModel {
    private let householdId: UUID
    private let userId: UUID
    private let choreId = UUID()

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
        canContinueWithDetails && canContinueWithSchedule && !didSave
            && selectedMemberIds.isSubset(of: availableMemberIds)
            && (!requiresApproval || (requiredApprovalCount > 0
                && requiredApprovalCount <= availableMemberIds.count))
    }

    private var creation: ChoreCreation {
        ChoreCreation(
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

    func create(using repository: any ChoreRepositoryProtocol) {
        guard !didSave else { return }
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
        do {
            try repository.create(creation)
            didSave = true
        } catch LocalChoreStoreError.invalidDetails {
            errorMessage = AppLocalization.string("chores.error.details")
        } catch LocalChoreStoreError.invalidSchedule {
            errorMessage = AppLocalization.string("chores.error.schedule")
        } catch LocalChoreStoreError.invalidMembers {
            errorMessage = AppLocalization.string("chores.error.members")
        } catch LocalChoreStoreError.householdUnavailable {
            errorMessage = AppLocalization.string("household.unavailableHelp")
        } catch LocalChoreStoreError.permissionDenied {
            errorMessage = AppLocalization.string("chores.error.permission")
        } catch {
            errorMessage = AppLocalization.string("chores.error.save")
        }
    }
}
