import Foundation
import Observation

@Observable
@MainActor
final class CreateHouseholdViewModel {
    enum Step: Hashable { case name, description }

    var name = ""
    var description = ""
    var step: Step = .name
    private(set) var isCreating = false
    private(set) var creationSucceeded = false
    var errorMessage: String?

    @ObservationIgnored
    private let householdRepository: any HouseholdRepositoryProtocol
    
    @ObservationIgnored private let householdId = UUID()
    @ObservationIgnored private let roleId = UUID()
    @ObservationIgnored private let memberId = UUID()
    @ObservationIgnored private var lastRequest: CreateHouseholdRequest?
    @ObservationIgnored private var idempotencyKey = UUID()

    init(householdRepository: any HouseholdRepositoryProtocol) {
        self.householdRepository = householdRepository
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    var canContinue: Bool { !trimmedName.isEmpty && trimmedName.utf16.count <= 100 && !isCreating }
    
    var canCreate: Bool { canContinue && description.utf16.count <= 500 && !creationSucceeded }

    func create() async {
        guard step == .description, canCreate else { return }
        
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }

        let request = CreateHouseholdRequest(
            householdId: householdId, name: trimmedName,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description,
            roles: [CreateHouseholdRoleRequest(householdRoleId: roleId, name: "Owner", permissions: Set(HouseholdPermission.allCases))],
            creatorRoleId: roleId, householdMemberId: memberId
        )
        do {
            // Reuse the key for identical retries, but not for an edited payload.
            if lastRequest?.name != request.name || lastRequest?.description != request.description {
                idempotencyKey = UUID()
                lastRequest = request
            }
            try await householdRepository.create(lastRequest ?? request, idempotencyKey: idempotencyKey)
            creationSucceeded = true
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
