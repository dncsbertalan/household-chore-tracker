import Foundation
import Observation

/// Shared presentation state. Every read and write goes through the remote repositories.
@MainActor
@Observable
final class HouseholdStore: HouseholdRepositoryProtocol, ChoreRepositoryProtocol, HouseholdRoleRepositoryProtocol, HouseholdDeletionRepositoryProtocol, ChoreDeletionRepositoryProtocol, HouseholdUpdateRepositoryProtocol {
    private let householdRepository: (any HouseholdRepositoryProtocol)?
    private let roleRepository: (any HouseholdRoleRepositoryProtocol)?
    private let choreRepository: (any ChoreRepositoryProtocol)?
    private(set) var households: [Household] = []
    private(set) var chores: [ChoreResponse] = []
    private var accountId: UUID?
    private var session = UUID()
    private var revision = 0
    private var deletedChores: Set<UUID> = []
    private var deletedHouseholds: Set<UUID> = []
    private var membershipEpochs: [UUID: Int] = [:]
    private var reads: [String: UUID] = [:]

    init(households: (any HouseholdRepositoryProtocol)? = nil, chores: (any ChoreRepositoryProtocol)? = nil, roles: (any HouseholdRoleRepositoryProtocol)? = nil) {
        householdRepository = households
        choreRepository = chores
        roleRepository = roles
    }

    func clearSession() {
        session = UUID()
        accountId = nil
        households = []
        chores = []
        reads = [:]
        membershipEpochs = [:]
        deletedHouseholds = []
        deletedChores = []
        revision += 1
    }

    func beginSession(accountId: UUID) {
        if self.accountId != accountId {
            clearSession()
            self.accountId = accountId
        }
    }

    func household(id: UUID) -> Household? { households.first { $0.id == id } }

    func households(accountId: UUID) async throws -> [Household] {
        guard let householdRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, revision = revision, request = UUID()
        reads["households"] = request
        let result = try await householdRepository.households(accountId: accountId)
        try verify(session, accountId: accountId)
        guard self.revision == revision, reads["households"] == request else { throw CancellationError() }
        households = result.filter { !deletedHouseholds.contains($0.id) }
        let ids = Set(households.map(\.id))
        chores.removeAll { !ids.contains($0.householdId) }
        return households
    }

    func household(id: UUID, accountId: UUID) async throws -> Household {
        guard let householdRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, revision = revision, request = UUID(), key = "household-\(id)"
        reads[key] = request
        let result = try await householdRepository.household(id: id, accountId: accountId)
        try verify(session, accountId: accountId)
        guard self.revision == revision, reads[key] == request else { throw CancellationError() }
        guard !deletedHouseholds.contains(result.id) else { throw CancellationError() }
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
        let response = try await choreRepository.chores(accountId: accountId, householdId: householdId)
        let result = response.filter { !deletedHouseholds.contains($0.householdId) && !deletedChores.contains($0.id) }
        try verify(session, accountId: accountId)
        guard self.revision == revision, reads[key] == request else { throw CancellationError() }
        if let householdId { chores.removeAll { $0.householdId == householdId }; chores.append(contentsOf: result) }
        else { chores = result }
        return result
    }

    func create(_ creation: HouseholdCreation) async throws -> Household {
        guard let householdRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: creation.creatorUserId)
        let session = session
        let result = try await householdRepository.create(creation)
        try verify(session, accountId: creation.creatorUserId)
        guard !deletedHouseholds.contains(result.id) else { throw CancellationError() }
        record(result)
        return result
    }

    func create(_ creation: ChoreCreation) async throws -> ChoreResponse {
        guard let choreRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: creation.createdByUserId)
        let session = session, membershipEpochs = membershipEpochs
        let result = try await choreRepository.create(creation)
        try verify(session, accountId: creation.createdByUserId)
        try verifyMembership(result.householdId, epochs: membershipEpochs)
        try verifyChore(result.id)
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
        guard !deletedHouseholds.contains(result.householdId) else { throw CancellationError() }
        try verifyChore(result.id)
        replaceChore(result)
        return result
    }

    func update(id: UUID, accountId: UUID, request: UpdateChoreRequest, requestId: UUID) async throws -> ChoreResponse {
        guard let choreRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, membershipEpochs = membershipEpochs
        let result = try await choreRepository.update(id: id, accountId: accountId, request: request, requestId: requestId)
        try verify(session, accountId: accountId)
        try verifyMembership(result.householdId, epochs: membershipEpochs)
        try verifyChore(result.id)
        replaceChore(result)
        revision += 1
        return result
    }

    func perform(id: UUID, accountId: UUID, action: ChoreAction, request: ChoreActionRequest, requestId: UUID) async throws -> ChoreResponse {
        guard let choreRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, membershipEpochs = membershipEpochs
        let response = try await choreRepository.perform(id: id, accountId: accountId, action: action, request: request, requestId: requestId)
        try verify(session, accountId: accountId)
        try verifyMembership(response.householdId, epochs: membershipEpochs)
        try verifyChore(response.id)
        replaceChore(response)
        revision += 1
        return response
    }

    func roles(householdId: UUID, accountId: UUID) async throws -> HouseholdRolesResponse {
        guard let roleRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, revision = revision, request = UUID(), key = "roles-\(householdId)"
        reads[key] = request
        let response = try await roleRepository.roles(householdId: householdId, accountId: accountId)
        try verify(session, accountId: accountId)
        guard self.revision == revision, reads[key] == request else { throw CancellationError() }
        guard !deletedHouseholds.contains(response.household.id) else { throw CancellationError() }
        replaceHousehold(response.household)
        return response
    }

    func createRole(householdId: UUID, accountId: UUID, request: SaveHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        guard let roleRepository else { throw APIError.invalidResponse }
        return try await roleChange(householdId: householdId, accountId: accountId) {
            try await roleRepository.createRole(householdId: householdId, accountId: accountId, request: request, requestId: requestId)
        }
    }
    func updateRole(householdId: UUID, roleId: UUID, accountId: UUID, request: UpdateHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        guard let roleRepository else { throw APIError.invalidResponse }
        return try await roleChange(householdId: householdId, accountId: accountId) {
            try await roleRepository.updateRole(householdId: householdId, roleId: roleId, accountId: accountId, request: request, requestId: requestId)
        }
    }
    func deleteRole(householdId: UUID, roleId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdRolesResponse {
        guard let roleRepository else { throw APIError.invalidResponse }
        return try await roleChange(householdId: householdId, accountId: accountId) {
            try await roleRepository.deleteRole(householdId: householdId, roleId: roleId, version: version, accountId: accountId, requestId: requestId)
        }
    }
    func assignRole(householdId: UUID, memberId: UUID, accountId: UUID, request: AssignHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        guard let roleRepository else { throw APIError.invalidResponse }
        return try await roleChange(householdId: householdId, accountId: accountId) {
            try await roleRepository.assignRole(householdId: householdId, memberId: memberId, accountId: accountId, request: request, requestId: requestId)
        }
    }
    func removeMember(householdId: UUID, memberId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdMemberRemovalResponse {
        guard let roleRepository else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, membershipEpochs = membershipEpochs
        let response = try await roleRepository.removeMember(householdId: householdId, memberId: memberId,
            version: version, accountId: accountId, requestId: requestId)
        try verify(session, accountId: accountId)
        try verifyMembership(householdId, epochs: membershipEpochs)
        if let management = response.management { replaceHousehold(management.household) }
        else {
            households.removeAll { $0.id == householdId }
            self.membershipEpochs[householdId, default: 0] += 1
        }
        // Removal changes live assignments; discard cached chore details until the next server read.
        chores.removeAll { $0.householdId == householdId }
        revision += 1
        return response
    }

    func updateHousehold(id: UUID, accountId: UUID, request: UpdateHouseholdRequest, requestId: UUID) async throws -> Household {
        guard let updating = householdRepository as? any HouseholdUpdateRepositoryProtocol else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, membershipEpochs = membershipEpochs
        let response = try await updating.updateHousehold(id: id, accountId: accountId, request: request, requestId: requestId)
        try verify(session, accountId: accountId)
        try verifyMembership(id, epochs: membershipEpochs)
        replaceHousehold(response)
        households.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        revision += 1
        return response
    }

    func deleteHousehold(id: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws {
        guard let deletion = householdRepository as? any HouseholdDeletionRepositoryProtocol else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session
        try await deletion.deleteHousehold(id: id, version: version, accountId: accountId, requestId: requestId)
        try verify(session, accountId: accountId)
        deletedHouseholds.insert(id)
        membershipEpochs[id, default: 0] += 1
        households.removeAll { $0.id == id }
        chores.removeAll { $0.householdId == id }
        revision += 1
    }

    func deleteChore(id: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws {
        guard let deletion = choreRepository as? any ChoreDeletionRepositoryProtocol else { throw APIError.invalidResponse }
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session
        try await deletion.deleteChore(id: id, version: version, accountId: accountId, requestId: requestId)
        try verify(session, accountId: accountId)
        deletedChores.insert(id)
        chores.removeAll { $0.id == id }
        revision += 1
    }

    private func verifyChore(_ id: UUID) throws {
        guard !deletedChores.contains(id) else { throw CancellationError() }
    }

    func isHouseholdDeleted(_ id: UUID) -> Bool { deletedHouseholds.contains(id) }

    private func roleChange(householdId: UUID, accountId: UUID, operation: () async throws -> HouseholdRolesResponse) async throws -> HouseholdRolesResponse {
        try Task.checkCancellation()
        beginSession(accountId: accountId)
        let session = session, membershipEpochs = membershipEpochs
        let response = try await operation()
        try verify(session, accountId: accountId)
        try verifyMembership(householdId, epochs: membershipEpochs)
        replaceHousehold(response.household)
        revision += 1
        return response
    }
    private func replaceHousehold(_ household: Household) {
        if let index = households.firstIndex(where: { $0.id == household.id }) { households[index] = household }
        else { households.append(household) }
    }

    func record(_ household: Household) {
        guard !deletedHouseholds.contains(household.id) else { return }
        households.removeAll { $0.id == household.id }
        households.append(household)
        households.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        revision += 1
    }

    private func replaceChore(_ response: ChoreResponse) {
        if let index = chores.firstIndex(where: { $0.id == response.id }) { chores[index] = response }
        else { chores.append(response) }
    }

    private func verifyMembership(_ householdId: UUID, epochs: [UUID: Int]) throws {
        guard !deletedHouseholds.contains(householdId), membershipEpochs[householdId, default: 0] == epochs[householdId, default: 0] else { throw CancellationError() }
    }

    private func verify(_ session: UUID, accountId: UUID) throws {
        try Task.checkCancellation()
        guard self.session == session, self.accountId == accountId else { throw CancellationError() }
    }
}
