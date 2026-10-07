#if DEBUG
import Foundation

/// Keeps previews interactive without contacting the backend or creating real accounts.
nonisolated struct RegistrationPreviewService: Registering {
    func register(_ request: RegistrationRequest) async throws -> RegistrationResponse {
        RegistrationResponse(
            id: UUID(), email: request.email,
            firstName: request.firstName, lastName: request.lastName
        )
    }
}
#endif
