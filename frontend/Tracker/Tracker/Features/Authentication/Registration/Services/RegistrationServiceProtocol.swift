nonisolated protocol RegistrationServiceProtocol: Sendable {
    func register(_ request: RegistrationRequest) async throws -> RegistrationResponse
}
