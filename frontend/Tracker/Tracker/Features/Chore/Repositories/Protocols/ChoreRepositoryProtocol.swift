import Foundation

nonisolated protocol ChoreRepositoryProtocol: Sendable {
    func create(_ request: CreateChoreRequest, idempotencyKey: UUID) async throws
}
