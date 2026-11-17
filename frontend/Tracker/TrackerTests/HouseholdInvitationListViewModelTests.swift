import XCTest
@testable import Tracker

@MainActor
final class HouseholdInvitationListViewModelTests: XCTestCase {
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
