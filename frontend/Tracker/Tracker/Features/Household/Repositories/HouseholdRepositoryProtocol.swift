import Foundation

@MainActor
protocol HouseholdRepositoryProtocol {
    func households(accountId: UUID) async throws -> [HouseholdResponse]
    func household(id: UUID, accountId: UUID) async throws -> HouseholdResponse
    func create(_ creation: HouseholdCreation) async throws -> HouseholdResponse
}
