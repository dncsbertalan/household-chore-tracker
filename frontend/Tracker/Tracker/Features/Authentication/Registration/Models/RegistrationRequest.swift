nonisolated struct RegistrationRequest: Encodable, Sendable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}
