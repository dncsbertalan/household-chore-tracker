import Foundation
import Observation

@Observable
@MainActor
final class ChoreDetailViewModel {
    private(set) var chore: ChoreResponse?
    private(set) var isLoading = false
    private(set) var isStarting = false
    var errorMessage: String?
    private(set) var household: HouseholdResponse?
    private(set) var isActing = false
    var isBusy: Bool { isStarting || isActing || isLoading }
    
    @ObservationIgnored
    private let householdRepository: any HouseholdRepositoryProtocol
    
    @ObservationIgnored private var mutationKeys: [String: UUID] = [:]

    var canAssignMembers: Bool {
        guard let chore, let household else { return false }
        let permissions = household.me.householdRole.permissions
        let editable = chore.occurrence == nil || chore.occurrence?.occurrenceStatus == .pending || chore.occurrence?.occurrenceStatus == .inProgress
        return editable && permissions.contains(.choreUpdate) && permissions.contains(.choreAssignMember)
    }

    @ObservationIgnored private let choreId: UUID
    @ObservationIgnored private let repository: any ChoreRepositoryProtocol
    @ObservationIgnored private var startVersion: Int64?
    @ObservationIgnored private var startKey = UUID()

    init(choreId: UUID, repository: any ChoreRepositoryProtocol, householdRepository: any HouseholdRepositoryProtocol) {
        self.householdRepository = householdRepository
        self.choreId = choreId
        self.repository = repository
    }

    func load() async {
        guard !isBusy else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await repository.get(choreId: choreId)
            try Task.checkCancellation()
            chore = response
            household = try await householdRepository.get(householdId: response.householdId)
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func startOccurrence() async {
        guard let chore, chore.isOnDemand, chore.actions?.canCreateOccurrence == true, !isBusy else { return }
        isStarting = true
        errorMessage = nil
        defer { isStarting = false }
        if startVersion != chore.version { startVersion = chore.version; startKey = UUID() }
        do {
            self.chore = try await repository.startOccurrence(choreId: choreId, version: chore.version, idempotencyKey: startKey)
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func perform(_ action: ChoreAction) async {
        guard let chore, !isBusy else { return }
        switch action {
        case .complete(let id):
            guard chore.actions?.canComplete == true, id == chore.occurrence?.id else { return }
        case .approve(let id):
            guard chore.actions?.canApprove == true, id == chore.pendingCompletion?.id else { return }
        case .reject(let id):
            guard chore.actions?.canReject == true, id == chore.pendingCompletion?.id else { return }
        }
        let request = ChoreActionRequest(version: chore.version, occurrenceVersion: chore.occurrence?.version,
                                         completionVersion: chore.pendingCompletion?.version)
        isActing = true
        errorMessage = nil
        defer { isActing = false }
        do {
            let key = try mutationKey(path: action.path, request: request)
            self.chore = try await repository.perform(choreId: choreId, action: action, request: request, idempotencyKey: key)
        } catch { errorMessage = error.localizedDescription }
    }

    func assignMembers(_ ids: Set<UUID>) async -> Bool {
        guard let chore, let household, canAssignMembers, !isBusy,
              ids.isSubset(of: Set(household.members.map(\.id))), ids != Set(chore.assignedMemberIds) else { return false }
        isActing = true
        errorMessage = nil
        defer { isActing = false }
        do {
            let request = UpdateChoreRequest(chore: chore, assignedMemberIds: ids)
            let key = try mutationKey(path: "update", request: request)
            self.chore = try await repository.update(choreId: choreId, request: request, idempotencyKey: key)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func mutationKey(path: String, request: some Encodable) throws -> UUID {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        let signature = path + (try encoder.encode(request)).base64EncodedString()
        if let key = mutationKeys[signature] { return key }
        let key = UUID()
        mutationKeys[signature] = key
        return key
    }

}
