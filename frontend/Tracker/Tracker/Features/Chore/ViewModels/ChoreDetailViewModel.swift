import Foundation
import Observation

@Observable
@MainActor
final class ChoreDetailViewModel {
    private(set) var chore: ChoreResponse?
    private(set) var isLoading = false
    private(set) var isStarting = false
    var errorMessage: String?
    @ObservationIgnored private let choreId: UUID
    @ObservationIgnored private let repository: any ChoreRepositoryProtocol
    @ObservationIgnored private var startVersion: Int64?
    @ObservationIgnored private var startKey = UUID()

    init(choreId: UUID, repository: any ChoreRepositoryProtocol) {
        self.choreId = choreId
        self.repository = repository
    }

    func load() async {
        guard !isLoading, !isStarting else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await repository.get(choreId: choreId)
            try Task.checkCancellation()
            chore = response
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func startOccurrence() async {
        guard let chore, chore.isOnDemand, chore.actions?.canCreateOccurrence == true, !isStarting, !isLoading else { return }
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
}
