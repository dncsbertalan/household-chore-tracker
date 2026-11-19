import Foundation
import Observation

@Observable
@MainActor
final class CreateChoreViewModel {
    let household: HouseholdResponse
    var title = ""
    var description = ""
    var pattern: ChoreCreationPattern = .once
    var recurrenceUnit: ChoreRecurrenceUnit = .week
    var recurrenceInterval = 1
    var hasScheduledDate = false
    var scheduledAt = Date()
    var hasDueDate = false
    var dueAt = Date().addingTimeInterval(3600)
    var assignedMemberIds: Set<UUID> = []
    var requiredApprovalCount = 0
    private(set) var isCreating = false
    private(set) var creationSucceeded = false
    var errorMessage: String?

    @ObservationIgnored private let repository: any ChoreRepositoryProtocol
    @ObservationIgnored private let choreId = UUID()
    @ObservationIgnored private let scheduleId = UUID()
    @ObservationIgnored private let occurrenceId = UUID()
    @ObservationIgnored private var lastRequest: CreateChoreRequest?
    @ObservationIgnored private var idempotencyKey = UUID()
    let timeZoneIdentifier = TimeZone.current.identifier

    init(household: HouseholdResponse, repository: any ChoreRepositoryProtocol) {
        self.household = household
        self.repository = repository
    }

    var request: CreateChoreRequest {
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return CreateChoreRequest(choreId: choreId, householdId: household.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines), description: description.isEmpty ? nil : description,
            pattern: pattern, recurrenceUnit: pattern.isRecurring ? recurrenceUnit : nil,
            recurrenceInterval: pattern.isRecurring ? recurrenceInterval : 1,
            scheduledAt: pattern != .onDemand && (hasScheduledDate || pattern == .fixed) ? scheduledAt : nil,
            dueAt: pattern != .onDemand && hasDueDate ? dueAt : nil, timeZoneIdentifier: timeZoneIdentifier,
            assignedMemberIds: assignedMemberIds.sorted { $0.uuidString < $1.uuidString }, requiredApprovalCount: requiredApprovalCount,
            choreScheduleId: pattern == .once ? nil : scheduleId,
            choreOccurrenceId: pattern == .onDemand ? nil : occurrenceId)
    }

    var canCreate: Bool {
        let request = request
        return household.me.householdRole.permissions.contains(.choreCreate) && !isCreating && !creationSucceeded
            && !request.title.isEmpty && request.title.utf16.count <= 100
            && (request.description?.utf16.count ?? 0) <= 500 && request.recurrenceInterval >= 1
            && requiredApprovalCount >= 0 && requiredApprovalCount <= household.members.count
            && assignedMemberIds.isSubset(of: Set(household.members.map(\.id)))
            && (request.scheduledAt == nil || request.dueAt == nil || request.dueAt! >= request.scheduledAt!)
    }

    func create() async {
        guard canCreate else { return }
        let request = request
        if lastRequest != request { lastRequest = request; idempotencyKey = UUID() }
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }
        do {
            try await repository.create(request, idempotencyKey: idempotencyKey)
            creationSucceeded = true
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
