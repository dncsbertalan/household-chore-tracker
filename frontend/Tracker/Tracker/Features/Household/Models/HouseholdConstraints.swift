import Foundation

nonisolated enum HouseholdConstraints {
    static let nameMaxLength = 100
    static let descriptionMaxLength = 500
    static let roleNameMaxLength = 50

    static func trimmedText(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Java @Size measures UTF-16 code units, including two units for most emoji.
    static func isValidName(_ value: String) -> Bool {
        let name = trimmedText(value)
        return !name.isEmpty && name.utf16.count <= nameMaxLength
    }

    static func isValidRoleName(_ value: String) -> Bool {
        let name = trimmedText(value)
        return !name.isEmpty && name.utf16.count <= roleNameMaxLength
    }
}
