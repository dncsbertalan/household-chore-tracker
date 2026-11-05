import Foundation

/// In-memory presentation state for invitation lists.
@MainActor
final class InvitationLists {
    struct Snapshot {
        let invitations: [HouseholdInvitationResponse]
        let fetchedAt: Date
    }

    private struct Contents {
        var accounts: [String: [String: Snapshot]] = [:]
    }

    private var contents = Contents()

    static func scope(householdId: UUID?) -> String { householdId?.uuidString ?? "inbox" }

    func snapshot(accountId: UUID, householdId: UUID? = nil) -> Snapshot? {
        contents.accounts[accountId.uuidString]?[Self.scope(householdId: householdId)]
    }

    func householdIds(accountId: UUID) -> [UUID] {
        (contents.accounts[accountId.uuidString] ?? [:]).keys.compactMap(UUID.init(uuidString:))
    }

    func save(_ invitations: [HouseholdInvitationResponse], accountId: UUID, householdId: UUID? = nil, fetchedAt: Date = .now) {
        contents.accounts[accountId.uuidString, default: [:]][Self.scope(householdId: householdId)] =
            Snapshot(invitations: invitations, fetchedAt: fetchedAt)
    }

    func record(_ invitation: HouseholdInvitationResponse, accountId: UUID) {
        // Only update lists that were actually fetched; a partial list must not appear complete.
        for scope in Array((contents.accounts[accountId.uuidString] ?? [:]).keys) {
            guard let old = contents.accounts[accountId.uuidString]?[scope] else { continue }
            var invitations = old.invitations.filter { $0.id != invitation.id }
            if scope == invitation.householdId.uuidString || (scope == "inbox" && old.invitations.contains { $0.id == invitation.id } && invitation.isPending()) {
                invitations.insert(invitation, at: 0)
            }
            contents.accounts[accountId.uuidString]?[scope] = Snapshot(invitations: invitations, fetchedAt: old.fetchedAt)
        }
    }

    func remove(id: UUID, accountId: UUID) {
        for scope in Array((contents.accounts[accountId.uuidString] ?? [:]).keys) {
            guard let old = contents.accounts[accountId.uuidString]?[scope] else { continue }
            contents.accounts[accountId.uuidString]?[scope] = Snapshot(
                invitations: old.invitations.filter { $0.id != id }, fetchedAt: old.fetchedAt)
        }
    }

    func removeHousehold(_ householdId: UUID) {
        for account in Array(contents.accounts.keys) {
            contents.accounts[account]?.removeValue(forKey: householdId.uuidString)
            for scope in Array((contents.accounts[account] ?? [:]).keys) {
                guard let old = contents.accounts[account]?[scope] else { continue }
                contents.accounts[account]?[scope] = Snapshot(invitations: old.invitations.filter { $0.householdId != householdId }, fetchedAt: old.fetchedAt)
            }
        }
    }

    func clear() { contents = Contents() }
}
