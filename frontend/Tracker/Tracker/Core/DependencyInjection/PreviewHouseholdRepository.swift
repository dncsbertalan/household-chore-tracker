import Foundation

nonisolated struct PreviewHouseholdRepository: HouseholdRepositoryProtocol {
    static let mockedData = [
        HouseholdSummaryResponse(
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
        ),
        HouseholdSummaryResponse(
            householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!,
            name: "Második otthon",
            description: nil,
            members: [
                HouseholdMemberResponse(
                    householdMemberId: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!,
                    householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!,
                    userId: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!, email: "poko@icloud.com", firstName: "Kincső", lastName: "Pokó", nickname: "Kincső",
                    householdRole: HouseholdRoleResponse(
                        householdRoleId: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!,
                        householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!, name: "Owner", isSystemRole: false,
                        permissions: [], createdAt: .now, updatedAt: .now, version: 1),
                    joinedAt: Date(), createdAt: Date(), updatedAt: .now, version: 1
                )
            ]
        )
    ]
    
    func getSummaries() async throws -> [HouseholdSummaryResponse] {
        PreviewHouseholdRepository.mockedData
    }
}
