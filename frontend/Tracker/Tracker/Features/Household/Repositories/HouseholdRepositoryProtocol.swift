import Foundation

@MainActor
protocol HouseholdRepositoryProtocol {
    func households(accountId: UUID) async throws -> [Household]
    func household(id: UUID, accountId: UUID) async throws -> Household
    func create(_ creation: HouseholdCreation) async throws -> Household
}
