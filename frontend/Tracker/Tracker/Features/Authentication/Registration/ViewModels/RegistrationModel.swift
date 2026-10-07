import Foundation
import Observation

@MainActor
@Observable
final class RegistrationModel {
    var email = ""
    var password = ""
    var firstName = ""
    var lastName = ""
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?
    private(set) var registeredUser: RegistrationResponse?

    private let service: any Registering

    init(service: any Registering) {
        self.service = service
    }

    func register() async {
        guard !isSubmitting else { return }
        errorMessage = nil
        registeredUser = nil
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !firstName.isEmpty, !lastName.isEmpty,
              !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = String(localized: "registration.error.required")
            return
        }
        // Java's @Size counts UTF-16 code units. Preserve the password exactly as entered.
        guard email.utf16.count <= 255, firstName.utf16.count <= 100,
              lastName.utf16.count <= 100, (12...128).contains(password.utf16.count) else {
            errorMessage = String(localized: "registration.error.length")
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let response = try await service.register(RegistrationRequest(
                email: email, password: password, firstName: firstName, lastName: lastName
            ))
            try Task.checkCancellation()
            registeredUser = response
            password = ""
        } catch is CancellationError {
            // Leaving the screen should not display a network failure.
        } catch APIError.http(let status, let problem) {
            switch status {
            case 400:
                let messages: [String] = problem?.errors?.map { fieldError -> String in
                    switch fieldError.field {
                    case "email": String(localized: "registration.error.email")
                    case "password": String(localized: "registration.error.password")
                    case "firstName": String(localized: "registration.error.firstName")
                    case "lastName": String(localized: "registration.error.lastName")
                    default: String(localized: "registration.error.fields")
                    }
                } ?? []
                errorMessage = messages.isEmpty ? String(localized: "registration.error.fields") : messages.joined(separator: "\n")
            case 403: errorMessage = String(localized: "auth.error.csrf")
            case 409: errorMessage = String(localized: "registration.error.duplicate")
            default: errorMessage = String(localized: "registration.error.http", defaultValue: "Registration failed (HTTP \(status)). Please try again later.")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
