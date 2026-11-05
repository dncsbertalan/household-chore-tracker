import Foundation

@MainActor
protocol HouseholdUpdateRepositoryProtocol {
    func updateHousehold(id: UUID, accountId: UUID, request: UpdateHouseholdRequest, requestId: UUID) async throws -> HouseholdResponse
}
