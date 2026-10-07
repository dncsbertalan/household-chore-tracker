import Foundation
import Observation

@MainActor
@Observable
final class LoginModel {
    var email = ""
    var password = ""
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?
    private(set) var didSignIn = false
    private let service: any SigningIn

    init(service: any SigningIn) { self.service = service }

    func login() async {
        guard !isSubmitting else { return }
        errorMessage = nil
        didSignIn = false
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, email.utf16.count <= 255,
              !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              password.utf16.count <= 128 else {
            errorMessage = String(localized: "login.error.required")
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await service.login(LoginRequest(email: email, password: password))
            try Task.checkCancellation()
            password = ""
            didSignIn = true
        } catch is CancellationError {
        } catch APIError.http(let status, _) {
            switch status {
            case 400: errorMessage = String(localized: "login.error.fields")
            case 401: errorMessage = String(localized: "login.error.credentials")
            case 403: errorMessage = String(localized: "auth.error.csrf")
            default: errorMessage = String(localized: "login.error.http", defaultValue: "Sign-in failed (HTTP \(status)). Please try again later.")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
