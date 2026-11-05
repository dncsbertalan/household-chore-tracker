import Foundation

@MainActor
protocol ChoreDeletionRepositoryProtocol {
    /// Invoke after explicit confirmation to delete the entire chore, its schedule, and all history.
    func deleteChore(id: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws
}
