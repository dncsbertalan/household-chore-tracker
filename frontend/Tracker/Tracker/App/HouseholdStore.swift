import Foundation
import Observation

/// Shared presentation state. Every read and write goes through the remote repositories.
@MainActor
@Observable
final class HouseholdStore: HouseholdRepositoryProtocol, ChoreRepositoryProtocol {
    private let householdRepository: (any HouseholdRepositoryProtocol)?
    private let choreRepository: (any ChoreRepositoryProtocol)?
    private(set) var households: [HouseholdResponse] = []
    private(set) var chores: [ChoreResponse] = []
    private var accountId: UUID?
    private var session = UUID()
    private var revision = 0
    private var reads: [String: UUID] = [:]

    init(households: (any HouseholdRepositoryProtocol)? = nil, chores: (any ChoreRepositoryProtocol)? = nil) {
        householdRepository = households
        choreRepository = chores
    }

    func clearSession() {
        session = UUID()
        accountId = nil
        households = []
        chores = []
        reads = [:]
        revision += 1
    }

    func beginSession(accountId: UUID) {
        if self.accountId != accountId {
            clearSession()
            self.accountId = accountId
        }
    }

    func household(id: UUID) -> HouseholdResponse? { households.first { $0.id == id } }

    func households(accountId: UUID) async throws -> [HouseholdResponse] {
        guard let householdRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, revision = revision, request = UUID()
        reads["households"] = request
        let result = try await householdRepository.households(accountId: accountId)
        try verify(session, accountId: accountId)
        guard self.revision == revision, reads["households"] == request else { throw CancellationError() }
        households = result
        let ids = Set(result.map(\.id))
        chores.removeAll { !ids.contains($0.householdId) }
        return result
    }

    func household(id: UUID, accountId: UUID) async throws -> HouseholdResponse {
        guard let householdRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, revision = revision, request = UUID(), key = "household-\(id)"
        reads[key] = request
        let result = try await householdRepository.household(id: id, accountId: accountId)
        try verify(session, accountId: accountId)
        guard self.revision == revision, reads[key] == request else { throw CancellationError() }
        if let index = households.firstIndex(where: { $0.id == result.id }) { households[index] = result }
        else { households.append(result) }
        return result
    }

    func chores(accountId: UUID, householdId: UUID? = nil) async throws -> [ChoreResponse] {
        guard let choreRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, revision = revision, request = UUID(), key = "chores-\(householdId?.uuidString ?? "all")"
        reads[key] = request
        let result = try await choreRepository.chores(accountId: accountId, householdId: householdId)
        try verify(session, accountId: accountId)
        guard self.revision == revision, reads[key] == request else { throw CancellationError() }
        if let householdId { chores.removeAll { $0.householdId == householdId }; chores.append(contentsOf: result) }
        else { chores = result }
        return result
    }

    func create(_ creation: HouseholdCreation) async throws -> HouseholdResponse {
        guard let householdRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: creation.creatorUserId)
        let session = session
        let result = try await householdRepository.create(creation)
        try verify(session, accountId: creation.creatorUserId)
        record(result)
        return result
    }

    func create(_ creation: ChoreCreation) async throws -> ChoreResponse {
        guard let choreRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: creation.createdByUserId)
        let session = session
        let result = try await choreRepository.create(creation)
        try verify(session, accountId: creation.createdByUserId)
        chores.removeAll { $0.id == result.id }
        chores.insert(result, at: 0)
        revision += 1
        return result
    }

    func chore(id: UUID) -> ChoreResponse? { chores.first { $0.id == id } }

    func chore(id: UUID, accountId: UUID) async throws -> ChoreResponse {
        guard let choreRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, revision = revision, request = UUID(), key = "chore-\(id)"
        reads[key] = request
        let result = try await choreRepository.chore(id: id, accountId: accountId)
        try verify(session, accountId: accountId)
        guard self.revision == revision, reads[key] == request else { throw CancellationError() }
        replaceChore(result)
        return result
    }

    func update(id: UUID, accountId: UUID, request: UpdateChoreRequest, requestId: UUID) async throws -> ChoreResponse {
        guard let choreRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session
        let result = try await choreRepository.update(id: id, accountId: accountId, request: request, requestId: requestId)
        try verify(session, accountId: accountId)
        replaceChore(result)
        revision += 1
        return result
    }

    func perform(id: UUID, accountId: UUID, action: ChoreAction, request: ChoreActionRequest, requestId: UUID) async throws -> ChoreResponse {
        guard let choreRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session
        let response = try await choreRepository.perform(id: id, accountId: accountId, action: action, request: request, requestId: requestId)
        try verify(session, accountId: accountId)
        replaceChore(response)
        revision += 1
        return response
    }

    func record(_ household: HouseholdResponse) {
        households.removeAll { $0.id == household.id }
        households.append(household)
        households.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        revision += 1
    }

    private func replaceChore(_ response: ChoreResponse) {
        if let index = chores.firstIndex(where: { $0.id == response.id }) { chores[index] = response }
        else { chores.append(response) }
    }

    private func verify(_ session: UUID, accountId: UUID) throws {
        try Task.checkCancellation()
        guard self.session == session, self.accountId == accountId else { throw CancellationError() }
    }
}
