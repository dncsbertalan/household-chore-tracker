import Foundation

nonisolated struct PreviewHouseholdRepository: HouseholdRepositoryProtocol {
    static let mockedData = [
        HouseholdSummaryResponse(
            householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Home",
            description: nil,
            members: [
                HouseholdMemberResponse.mockData
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
    
    func assignRole(householdId: UUID, memberId: UUID, request: AssignHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdResponse {
        try await get(householdId: householdId)
    }

    func updateNickname(householdId: UUID, memberId: UUID, request: UpdateMemberNicknameRequest, idempotencyKey: UUID) async throws -> HouseholdMemberResponse {
        let member = Self.mockedData.flatMap(\.members).first { $0.id == memberId } ?? Self.mockedData[0].members[0]
        return HouseholdMemberResponse(householdMemberId: member.id, householdId: member.householdId, userId: member.userId,
            email: member.email, firstName: member.firstName, lastName: member.lastName, nickname: request.nickname,
            householdRole: member.householdRole, joinedAt: member.joinedAt, createdAt: member.createdAt, updatedAt: .now, version: member.version + 1)
    }

    func create(_ request: CreateHouseholdRequest, idempotencyKey: UUID) async throws {}

    func get(householdId: UUID) async throws -> HouseholdResponse {
        let summary = Self.mockedData.first { $0.id == householdId } ?? Self.mockedData[0]
        let owner = summary.members[0]
        return HouseholdResponse(householdId: summary.id, name: summary.name, description: summary.description,
                                 members: summary.members, roles: [owner.householdRole], owner: owner, me: owner, createdAt: .now)
    }

    func getSummaries() async throws -> [HouseholdSummaryResponse] {
        PreviewHouseholdRepository.mockedData
    }
}
