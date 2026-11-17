import Foundation

nonisolated struct PreviewHouseholdRepository: HouseholdRepositoryProtocol {
    func getSummaries() async throws -> [HouseholdSummaryResponse] {
        [HouseholdSummaryResponse(
            householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Home",
            description: nil,
            members: [
                HouseholdMemberResponse(
                    householdMemberId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                    householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                    userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, email: "dancs.bertalan@icloud.com", firstName: "Bertalan", lastName: "Dancs", nickname: "Berci",
                    householdRole: HouseholdRoleResponse(
                        householdRoleId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                        householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "Owner", isSystemRole: false,
                        permissions: [], createdAt: .now, updatedAt: .now, version: 1),
                    joinedAt: Date(), createdAt: Date(), updatedAt: .now, version: 1
                )
            ]
        )]
    }
}
