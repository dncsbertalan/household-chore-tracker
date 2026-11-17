import Foundation

nonisolated struct PreviewHouseholdRepository: HouseholdRepositoryProtocol {
    func getSummaries() async throws -> [HouseholdSummaryResponse] {
        [HouseholdSummaryResponse(
            householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Home",
            description: nil,
            members: []
        )]
    }
}
