import Foundation

nonisolated struct InviteHouseholdMemberRequest: Codable, Sendable, Equatable {
    let email: String
    let householdRoleId: UUID

    init(email: String, householdRoleId: UUID) {
        self.email = Self.normalizedEmail(email)
        self.householdRoleId = householdRoleId
    }

    static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "en_US_POSIX"))
    }

    static func isValidEmail(_ email: String) -> Bool {
        let email = normalizedEmail(email)
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        // The backend performs full email validation; catch common input mistakes locally.
        return email.utf16.count <= 255 && parts.count == 2
            && parts.allSatisfy { !$0.isEmpty }
            && !email.contains(where: { $0.isWhitespace })
    }
}
