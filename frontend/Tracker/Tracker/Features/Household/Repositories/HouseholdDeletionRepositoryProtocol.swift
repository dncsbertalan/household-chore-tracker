import Foundation

@MainActor
protocol HouseholdDeletionRepositoryProtocol {
    /// Invoke only after the member explicitly confirms the household and its data will be deleted.
    func deleteHousehold(id: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws
}
