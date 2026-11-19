import Foundation
import Observation

@Observable
@MainActor
final class HouseholdMemberDetailViewModel {
    private(set) var member: HouseholdMemberResponse
    private(set) var household: HouseholdResponse?
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?

    @ObservationIgnored private let repository: any HouseholdRepositoryProtocol
    @ObservationIgnored private var nicknameRequest: UpdateMemberNicknameRequest?
    @ObservationIgnored private var nicknameKey = UUID()
    @ObservationIgnored private var lastRequest: AssignHouseholdRoleRequest?
    @ObservationIgnored private var idempotencyKey = UUID()

    init(member: HouseholdMemberResponse, repository: any HouseholdRepositoryProtocol) {
        self.member = member
        self.repository = repository
    }

    var canAssignRole: Bool {
        household?.me.householdRole.permissions.contains(HouseholdPermission.memberAssignRole) == true
    }

    var roles: [HouseholdRoleResponse] { household?.roles ?? [] }

    func load() async {
        guard !isLoading, !isSaving else { return }
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            let response = try await repository.get(householdId: member.householdId)
            try Task.checkCancellation()
            update(response)
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func assign(_ role: HouseholdRoleResponse) async -> Bool {
        guard canAssignRole, !isSaving, !isLoading,
              roles.contains(where: { $0.id == role.id }), role.id != member.householdRole.id else { return false }
        
        isSaving = true
        errorMessage = nil
        
        defer { isSaving = false }
        
        let request = AssignHouseholdRoleRequest(roleId: role.id, memberVersion: member.version, roleVersion: role.version)
        if lastRequest != request {
            lastRequest = request
            idempotencyKey = UUID()
        }
        do {
            let response = try await repository.assignRole(householdId: member.householdId, memberId: member.id,
                                                           request: request, idempotencyKey: idempotencyKey)
            update(response)
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func canSaveNickname(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !isLoading && !isSaving && trimmed.utf16.count <= 100 && trimmed != (member.nickname ?? "")
    }

    func saveNickname(_ value: String) async -> Bool {
        guard canSaveNickname(value) else { return false }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = UpdateMemberNicknameRequest(nickname: trimmed.isEmpty ? nil : trimmed, version: member.version)
        if nicknameRequest != request { nicknameRequest = request; nicknameKey = UUID() }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            member = try await repository.updateNickname(householdId: member.householdId, memberId: member.id,
                                                          request: request, idempotencyKey: nicknameKey)
            return true
        } catch is CancellationError { return false }
        catch { errorMessage = error.localizedDescription; return false }
    }

    private func update(_ response: HouseholdResponse) {
        household = response
        if let updated = response.members.first(where: { $0.id == member.id }) { member = updated }
    }
}
