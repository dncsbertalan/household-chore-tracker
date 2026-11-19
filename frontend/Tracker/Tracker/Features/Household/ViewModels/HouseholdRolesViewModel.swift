import Foundation
import Observation

@Observable
@MainActor
final class HouseholdRolesViewModel {
    private(set) var response: HouseholdRolesResponse?
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?

    @ObservationIgnored
    private let repository: any HouseholdRoleRepositoryProtocol
    
    @ObservationIgnored private let householdId: UUID
    @ObservationIgnored private var keys: [String: UUID] = [:]

    init(householdId: UUID, repository: any HouseholdRoleRepositoryProtocol) {
        self.householdId = householdId
        self.repository = repository
    }
    
    var roles: [HouseholdRoleResponse] { response?.household.roles ?? [] }
    
    func canEdit(_ role: HouseholdRoleResponse) -> Bool {
        response?.actions.canUpdate == true && !role.isSystemRole && roles.contains { $0.id == role.id }
    }
    
    func canSave(_ role: HouseholdRoleResponse, name: String, permissions: Set<HouseholdPermission>) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return canEdit(role) && !isLoading && !isSaving && !trimmed.isEmpty && trimmed.utf16.count <= 50
            && (trimmed != role.name || permissions != Set(role.permissions))
            && !roles.contains { $0.id != role.id && $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed.lowercased() }
    }
    
    func load() async {
        guard !isLoading, !isSaving else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await repository.get(householdId: householdId)
            try Task.checkCancellation()
            response = result
        } catch is CancellationError {
        } catch { errorMessage = error.localizedDescription }
    }
    
    func save(_ role: HouseholdRoleResponse, name: String, permissions: Set<HouseholdPermission>) async -> Bool {
        guard canSave(role, name: name, permissions: permissions) else { return false }
        
        isSaving = true
        errorMessage = nil
        
        defer { isSaving = false }
        
        let request = UpdateHouseholdRoleRequest(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            permissions: permissions.sorted { $0.rawValue < $1.rawValue }, version: role.version)
        
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
            let signature = role.id.uuidString + (try encoder.encode(request)).base64EncodedString()
            let key = keys[signature] ?? UUID(); keys[signature] = key
            response = try await repository.update(householdId: householdId, roleId: role.id, request: request, idempotencyKey: key)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
