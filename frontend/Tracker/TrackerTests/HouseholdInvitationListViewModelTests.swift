import XCTest
@testable import Tracker

@MainActor
final class HouseholdInvitationListViewModelTests: XCTestCase {
    func testSuccessfulResponsesRefreshHouseholdsAndBadge() async {
        let invitations = ControlledInvitationRepository()
        let households = CountingHouseholdRepository()
        let parent = HouseholdsViewModel(householdRepository: households, householdInvitationRepository: invitations)
        await parent.load()
        XCTAssertEqual(parent.householdInvitations.count, 2)
        XCTAssertTrue(parent.householdSummaries.isEmpty)
        let inbox = parent.makeInvitationListViewModel()
        await inbox.load()
        let first = inbox.householdInvitations[0]
        let second = inbox.householdInvitations[1]

        let accept = Task { await inbox.accept(first) }
        await invitations.waitForRequests(1)
        await households.addHousehold()
        await invitations.complete(first.id)
        await accept.value
        XCTAssertEqual(parent.householdInvitations.map(\.id), [second.id])
        XCTAssertEqual(parent.householdSummaries.count, 1)

        let decline = Task { await inbox.decline(second) }
        await invitations.waitForRequests(2)
        await invitations.complete(second.id)
        await decline.value
        XCTAssertTrue(parent.householdInvitations.isEmpty)
        XCTAssertEqual(parent.householdSummaries.count, 1)
        let calls = await households.calls
        XCTAssertEqual(calls, 3)
    }

    func testRequestsAreIndependentAndDuplicateActionsAreIgnored() async {
        let repository = ControlledInvitationRepository()
        let viewModel = HouseholdInvitationListViewModel(householdInvitationRepository: repository)
        await viewModel.load()
        let first = viewModel.householdInvitations[0]
        let second = viewModel.householdInvitations[1]

        let accept = Task { await viewModel.accept(first) }
        await repository.waitForRequests(1)
        XCTAssertEqual(viewModel.processingInvitationIDs, [first.id])
        await viewModel.decline(first)

        let decline = Task { await viewModel.decline(second) }
        await repository.waitForRequests(2)
        XCTAssertEqual(viewModel.processingInvitationIDs, [first.id, second.id])
        let count = await repository.requestCount
        XCTAssertEqual(count, 2)

        await repository.complete(first.id)
        await accept.value
        XCTAssertEqual(viewModel.processingInvitationIDs, [second.id])
        XCTAssertEqual(viewModel.householdInvitations.map(\.id), [second.id])

        await repository.complete(second.id, failing: true)
        await decline.value
        XCTAssertTrue(viewModel.processingInvitationIDs.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.householdInvitations.map(\.id), [second.id])

        let retry = Task { await viewModel.decline(second) }
        await repository.waitForRequests(3)
        let keys = await repository.keys
        XCTAssertEqual(keys[1], keys[2])
        await repository.complete(second.id)
        await retry.value
        XCTAssertTrue(viewModel.householdInvitations.isEmpty)
        // A stale inbox response must not reintroduce completed invitations.
        await viewModel.load()
        XCTAssertTrue(viewModel.householdInvitations.isEmpty)
    }
}

private actor ControlledInvitationRepository: HouseholdInvitationRepositoryProtocol {
    let invitations = (0..<2).map { _ in
        HouseholdInvitationDto(
            householdInvitationId: UUID(), householdId: UUID(), householdName: "Home",
            invitedByLastName: "Test", invitedByFirstName: "User", status: .pending,
            expiresAt: .distantFuture, createdAt: .now
        )
    }
    var keys: [UUID] = []
    var requestCount: Int { keys.count }
    private var pending: [UUID: CheckedContinuation<Void, any Error>] = [:]

    func getAllCurrentlyActive() async throws -> [HouseholdInvitationDto] { invitations }
    func accept(invitationId: UUID, idempotencyKey: UUID) async throws {
        try await suspend(invitationId, key: idempotencyKey)
    }
    func decline(invitationId: UUID, idempotencyKey: UUID) async throws {
        try await suspend(invitationId, key: idempotencyKey)
    }
    private func suspend(_ id: UUID, key: UUID) async throws {
        keys.append(key)
        try await withCheckedThrowingContinuation { pending[id] = $0 }
    }
    func waitForRequests(_ count: Int) async {
        while requestCount < count { await Task.yield() }
    }
    func complete(_ id: UUID, failing: Bool = false) {
        let continuation = pending.removeValue(forKey: id)
        if failing {
            continuation?.resume(throwing: URLError(.notConnectedToInternet))
        } else {
            continuation?.resume()
        }
    }
}

private actor CountingHouseholdRepository: HouseholdRepositoryProtocol {
    func create(_ request: CreateHouseholdRequest, idempotencyKey: UUID) async throws {}
    var calls = 0
    private var summaries: [HouseholdSummaryResponse] = []
    func getSummaries() async throws -> [HouseholdSummaryResponse] {
        calls += 1
        return summaries
    }
    func addHousehold() {
        summaries = [HouseholdSummaryResponse(householdId: UUID(), name: "Joined home", description: nil, members: [])]
    }
}
