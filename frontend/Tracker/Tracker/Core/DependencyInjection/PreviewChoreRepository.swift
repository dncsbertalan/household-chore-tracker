import Foundation

nonisolated struct PreviewChoreRepository: ChoreRepositoryProtocol {
    func create(_ request: CreateChoreRequest, idempotencyKey: UUID) async throws {}
}
