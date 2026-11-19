import Foundation
import Observation

@Observable
@MainActor
final class CreateHouseholdInvitationViewModel {
    var email = ""
    var selectedRoleId: UUID?
    private(set) var isInviting = false
    private(set) var invitationSucceeded = false
    var errorMessage: String?
    let household: HouseholdResponse

    @ObservationIgnored private let repository: any HouseholdInvitationRepositoryProtocol
    @ObservationIgnored private var lastRequest: InviteHouseholdMemberRequest?
    @ObservationIgnored private var idempotencyKey = UUID()

    init(household: HouseholdResponse, repository: any HouseholdInvitationRepositoryProtocol) {
        self.household = household
        self.repository = repository
        
        selectedRoleId = household.roles.first?.id
    }

    var normalizedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    var canInvite: Bool {
        household.me.householdRole.permissions.contains(.memberInvite)
            && !isInviting && !invitationSucceeded
            && household.roles.contains { $0.id == selectedRoleId }
            && normalizedEmail.utf16.count <= 255
            && normalizedEmail.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    func invite() async {
        guard canInvite, let selectedRoleId else { return }
        isInviting = true
        errorMessage = nil
        defer { isInviting = false }
        let request = InviteHouseholdMemberRequest(email: normalizedEmail, householdRoleId: selectedRoleId)
        if request != lastRequest {
            lastRequest = request
            idempotencyKey = UUID()
        }
        do {
            try await repository.invite(householdId: household.id, request: request, idempotencyKey: idempotencyKey)
            invitationSucceeded = true
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
