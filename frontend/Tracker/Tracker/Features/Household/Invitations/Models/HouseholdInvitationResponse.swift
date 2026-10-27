import Foundation

nonisolated enum HouseholdInvitationStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case declined = "DECLINED"
    case revoked = "REVOKED"
    case expired = "EXPIRED"
}

nonisolated struct HouseholdInvitationResponse: Codable, Sendable, Equatable, Identifiable {
    let householdInvitationId: UUID
    let householdId: UUID
    let householdName: String
    let email: String
    let invitedByUserId: UUID
    let householdRoleId: UUID
    let householdRoleName: String
    let status: HouseholdInvitationStatus
    let expiresAt: String
    let respondedAt: String?
    let createdAt: String
    let updatedAt: String
    let version: Int64

    var id: UUID { householdInvitationId }

    func isPending(at date: Date = .now) -> Bool {
        status == .pending && (InvitationTimestamp.date(expiresAt).map { $0 > date } ?? false)
    }

    var isValid: Bool {
        guard let created = InvitationTimestamp.date(createdAt),
              let expiry = InvitationTimestamp.date(expiresAt), expiry > created,
              InvitationTimestamp.date(updatedAt) != nil,
              version >= 0, InviteHouseholdMemberRequest.isValidEmail(email),
              email == InviteHouseholdMemberRequest.normalizedEmail(email),
              !householdName.isEmpty, !householdRoleName.isEmpty else { return false }
        if let respondedAt, InvitationTimestamp.date(respondedAt) == nil { return false }
        switch status {
        case .pending: return respondedAt == nil
        case .expired: return true // Expiry can be computed by a read without updating the stored row.
        default: return respondedAt != nil
        }
    }
}

nonisolated enum InvitationTimestamp {
    static func date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}
