import Foundation
import Observation

/// Presentation state for a single user-triggered write. Retries stay explicit.
@MainActor
@Observable
final class HouseholdRoleRequestState {
    private(set) var isPending = false
    private(set) var roleError: HouseholdRoleError?

    func run<Value>(_ operation: () async throws -> Value) async -> Value? {
        guard !isPending, roleError?.needsReload != true else { return nil }
        isPending = true
        roleError = nil
        defer { isPending = false }
        do {
            let value = try await operation()
            try Task.checkCancellation()
            return value
        } catch {
            if !HouseholdRoleFailure.isCancellation(error) { roleError = HouseholdRoleError(error) }
            return nil
        }
    }
}
