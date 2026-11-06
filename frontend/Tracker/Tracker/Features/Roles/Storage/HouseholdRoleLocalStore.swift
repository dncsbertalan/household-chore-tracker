import Foundation
import CryptoKit

nonisolated protocol HouseholdRoleLocalStore: Sendable {
    func load(_ scope: HouseholdRolesScope) async throws -> HouseholdRolesResponse?
    func save(_ response: HouseholdRolesResponse, for scope: HouseholdRolesScope) async throws
    func remove(_ scope: HouseholdRolesScope) async throws
}

/// File access and JSON work run on this actor, away from presentation state.
actor FileHouseholdRoleStore: HouseholdRoleLocalStore {
    private let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    init(namespace: String) {
        let namespace = SHA256.hash(data: Data(namespace.utf8)).map { String(format: "%02x", $0) }.joined()
        directory = URL.applicationSupportDirectory.appending(path: "Tracker/roles-v1/\(namespace)", directoryHint: .isDirectory)
    }

    func load(_ scope: HouseholdRolesScope) throws -> HouseholdRolesResponse? {
        let file = file(for: scope)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        do {
            let response = try JSONDecoder().decode(HouseholdRolesResponse.self, from: Data(contentsOf: file))
            guard response.household.id == scope.householdId else {
                try remove(scope)
                return nil
            }
            return response
        } catch {
            // An old schema or interrupted external edit must not prevent a network load.
            try? remove(scope)
            return nil
        }
    }

    func save(_ response: HouseholdRolesResponse, for scope: HouseholdRolesScope) throws {
        guard response.household.id == scope.householdId else { throw APIError.invalidResponse }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(response).write(to: file(for: scope), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func remove(_ scope: HouseholdRolesScope) throws {
        let file = file(for: scope)
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
    }

    private func file(for scope: HouseholdRolesScope) -> URL {
        directory.appending(path: "\(scope.accountId.uuidString)-\(scope.householdId.uuidString).json")
    }
}
