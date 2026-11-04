#if DEBUG
import Foundation

@MainActor
enum ChoreUITestFixture {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("--ui-test-chores") }
    static let userId = UUID(uuidString: "1A460DB1-9970-48EA-A93B-C08A66FA6701")!
    static let householdId = UUID(uuidString: "1A460DB1-9970-48EA-A93B-C08A66FA6702")!

    static func household() -> HouseholdResponse {
        var grants: [HouseholdPermission] = ProcessInfo.processInfo.arguments.contains("--ui-test-no-edit-permission")
            ? [.memberView] : [.choreCreate, .choreUpdate, .choreAssignMember, .memberView, .roleView]
        if ProcessInfo.processInfo.arguments.contains("--ui-test-completion") {
            grants += [.choreComplete, .choreApproveCompletion]
            if !ProcessInfo.processInfo.arguments.contains("--ui-test-no-self-approval") { grants.append(.choreSelfApproveCompletion) }
        }
        let role = HouseholdResponse.Role(householdRoleId: UUID(), householdId: householdId, name: "Member",
            isSystemRole: false, permissions: grants.map { .init(name: $0) }, version: 0)
        let member = HouseholdResponse.Member(householdMemberId: UUID(), householdId: householdId, userId: userId,
            nickname: "Alex", householdRole: role, joinedAt: "2026-11-04T12:00:00Z", version: 0)
        return HouseholdResponse(householdId: householdId, name: "Maple House", description: nil, createdByUserId: userId,
            version: 0, roles: [role], creatorMembership: nil, members: [member])
    }

    static func chore(pattern: ChoreCreationPattern, memberId: UUID, completed: Bool = false) -> ChoreResponse {
        let name: String = switch pattern {
        case .once: "Once chore"
        case .fixed: "Fixed chore"
        case .afterCompletion: "After completion chore"
        case .onDemand: "On demand chore"
        }
        let title = completed ? "Completed chore" : name
        let recurring = pattern == .fixed || pattern == .afterCompletion
        let schedule: ChoreResponse.Schedule? = pattern == .once ? nil : .init(choreScheduleId: UUID(),
            scheduleType: pattern.scheduleType!, recurrenceUnit: recurring ? .day : nil, recurrenceInterval: 1,
            startsAt: pattern == .fixed ? "2026-11-04T12:00:00Z" : nil, timeZoneIdentifier: "Europe/Budapest",
            version: 0, createdByHouseholdMemberId: memberId, updatedByHouseholdMemberId: memberId,
            createdAt: "2026-11-04T12:00:00Z", updatedAt: "2026-11-04T12:00:00Z")
        let occurrence: ChoreResponse.Occurrence? = pattern == .onDemand ? nil : .init(choreOccurrenceId: UUID(),
            title: title, description: "Chore description", assignedMemberIds: [memberId], requiredApprovalCount: 1,
            createdAt: "2026-11-04T12:00:00Z", scheduledAt: "2026-11-04T12:00:00Z", dueAt: "2026-11-05T12:00:00Z",
            occurrenceStatus: completed ? .completed : .pending, version: 0,
            createdByHouseholdMemberId: memberId, updatedByHouseholdMemberId: memberId, updatedAt: "2026-11-04T12:00:00Z")
        return ChoreResponse(choreId: UUID(), householdId: householdId, title: title, description: "Chore description",
            createdByUserId: userId, createdAt: "2026-11-04T12:00:00Z", version: 0, assignedMemberIds: [memberId],
            requiredApprovalCount: 1, schedule: schedule, occurrence: occurrence, occurrences: occurrence.map { [$0] } ?? [],
            createdByHouseholdMemberId: memberId, updatedByHouseholdMemberId: memberId, updatedAt: "2026-11-04T12:00:00Z")
    }
}

@MainActor
final class ChoreUITestRepository: HouseholdRepositoryProtocol, ChoreRepositoryProtocol {
    let home = ChoreUITestFixture.household()
    fileprivate var responses: [ChoreResponse]

    init() {
        let memberId = home.members[0].householdMemberId
        responses = ChoreCreationPattern.allCases.map { ChoreUITestFixture.chore(pattern: $0, memberId: memberId) }
        responses.append(ChoreUITestFixture.chore(pattern: .once, memberId: memberId, completed: true))
        if ProcessInfo.processInfo.arguments.contains("--ui-test-no-approval") {
            responses = responses.map { response in
                var json = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(response)) as! [String: Any]
                json["requiredApprovalCount"] = 0
                if var occurrence = json["occurrence"] as? [String: Any] {
                    occurrence["requiredApprovalCount"] = 0
                    json["occurrence"] = occurrence
                    json["occurrences"] = [occurrence]
                }
                return try! JSONDecoder().decode(ChoreResponse.self, from: JSONSerialization.data(withJSONObject: json))
            }
        }
    }
    func households(accountId: UUID) async throws -> [HouseholdResponse] { [home] }
    func household(id: UUID, accountId: UUID) async throws -> HouseholdResponse { home }
    func create(_ creation: HouseholdCreation) async throws -> HouseholdResponse { throw APIError.invalidResponse }
    func create(_ creation: ChoreCreation) async throws -> ChoreResponse { throw APIError.invalidResponse }
    func chores(accountId: UUID, householdId: UUID?) async throws -> [ChoreResponse] { responses.map(withActions) }
    func chore(id: UUID, accountId: UUID) async throws -> ChoreResponse {
        guard let response = responses.first(where: { $0.id == id }) else { throw APIError.invalidResponse }
        return withActions(response)
    }
    func update(id: UUID, accountId: UUID, request: UpdateChoreRequest, requestId: UUID) async throws -> ChoreResponse {
        try await Task.sleep(for: .milliseconds(400))
        if ProcessInfo.processInfo.arguments.contains("--ui-test-edit-fails") { throw APIError.transport(.timedOut) }
        if ProcessInfo.processInfo.arguments.contains("--ui-test-edit-conflict") { throw APIError.http(statusCode: 409, problem: nil) }
        let original = try await chore(id: id, accountId: accountId)
        guard original.isEditable else { throw APIError.http(statusCode: 409, problem: nil) }
        // UI fixtures only: apply the response fields to emulate a confirmed server update.
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as! [String: Any]
        let fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as! [String: Any]
        for key in ["title", "assignedMemberIds", "requiredApprovalCount"] { json[key] = fields[key] }
        json["description"] = request.description ?? NSNull() as Any
        json["version"] = original.version + 1
        if request.pattern == .once { json["schedule"] = NSNull() }
        else {
            var schedule = json["schedule"] as? [String: Any] ?? ["choreScheduleId": UUID().uuidString]
            schedule["scheduleType"] = request.pattern.scheduleType!.rawValue
            schedule["recurrenceUnit"] = request.recurrenceUnit?.rawValue ?? NSNull() as Any
            schedule["recurrenceInterval"] = request.recurrenceInterval
            schedule["startsAt"] = request.startsAt ?? NSNull() as Any
            schedule["timeZoneIdentifier"] = request.timeZoneIdentifier
            schedule["version"] = (original.schedule?.version ?? -1) + 1
            json["schedule"] = schedule
        }
        if original.occurrence != nil || request.pattern != .onDemand {
            var occurrence = json["occurrence"] as? [String: Any] ?? ["choreOccurrenceId": UUID().uuidString,
                "createdAt": "2026-11-04T12:00:00Z", "occurrenceStatus": "PENDING"]
            for key in ["title", "description", "assignedMemberIds", "requiredApprovalCount"] { occurrence[key] = json[key] }
            occurrence["scheduledAt"] = request.scheduledAt ?? NSNull() as Any
            occurrence["dueAt"] = request.dueAt ?? NSNull() as Any
            occurrence["version"] = (original.occurrence?.version ?? -1) + 1
            json["occurrence"] = occurrence
            json["occurrences"] = [occurrence]
        }
        let result = try JSONDecoder().decode(ChoreResponse.self, from: JSONSerialization.data(withJSONObject: json))
        responses.removeAll { $0.id == id }
        responses.append(result)
        return result
    }
}

extension ChoreUITestRepository {
    fileprivate func withActions(_ response: ChoreResponse) -> ChoreResponse {
        var response = response
        let member = home.members[0]
        let grants = member.householdRole.permissions.map(\.name)
        let current = response.occurrence
        let pending = response.pendingCompletion
        let review = grants.contains(.choreApproveCompletion) && current?.occurrenceStatus == .awaitingApproval
            && pending != nil && !(pending?.approvals.contains { $0.reviewedByHouseholdMemberId == member.householdMemberId } ?? false)
        let selfAllowed = pending?.completedByHouseholdMemberId != member.householdMemberId || grants.contains(.choreSelfApproveCompletion)
        response.actions = .init(canComplete: grants.contains(.choreComplete) && current?.isEditable == true,
            canApprove: review && selfAllowed, canReject: review,
            canCreateOccurrence: grants.contains(.choreComplete) && response.pattern == .onDemand
                && (current == nil || [.completed, .cancelled, .skipped].contains(current!.occurrenceStatus)))
        return response
    }

    func perform(id: UUID, accountId: UUID, action: ChoreAction, request: ChoreActionRequest, requestId: UUID) async throws -> ChoreResponse {
        try await Task.sleep(for: .milliseconds(400))
        if ProcessInfo.processInfo.arguments.contains("--ui-test-completion-fails") { throw APIError.transport(.timedOut) }
        if ProcessInfo.processInfo.arguments.contains("--ui-test-completion-conflict") { throw APIError.http(statusCode: 409, problem: nil) }
        let original = try await chore(id: id, accountId: accountId)
        guard request.version == original.version else { throw APIError.http(statusCode: 409, problem: nil) }
        let actor = home.members[0].householdMemberId.uuidString
        let now = ChoreTimestamp.encode(.now)!
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as! [String: Any]
        var history = json["occurrences"] as? [[String: Any]] ?? []
        var submissions = json["completions"] as? [[String: Any]] ?? []
        var current = json["occurrence"] as? [String: Any]
        var finalized = false
        func newOccurrence(scheduled: String?) -> [String: Any] {
            ["choreOccurrenceId": UUID().uuidString, "title": original.title,
             "description": original.description as Any? ?? NSNull(), "assignedMemberIds": original.assignedMemberIds.map(\.uuidString),
             "requiredApprovalCount": original.requiredApprovalCount, "createdAt": now, "scheduledAt": scheduled as Any? ?? NSNull(),
             "occurrenceStatus": "PENDING", "version": 0]
        }
        switch action {
        case .start:
            guard original.actions?.canCreateOccurrence == true else { throw APIError.http(statusCode: 409, problem: nil) }
            current = newOccurrence(scheduled: nil)
            history.insert(current!, at: 0)
        case .complete:
            guard original.actions?.canComplete == true, current != nil else { throw APIError.http(statusCode: 409, problem: nil) }
            finalized = original.occurrence!.requiredApprovalCount == 0
            current!["occurrenceStatus"] = finalized ? "COMPLETED" : "AWAITING_APPROVAL"
            current!["version"] = original.occurrence!.version + 1
            submissions.insert(["choreCompletionId": UUID().uuidString, "choreOccurrenceId": original.occurrence!.id.uuidString,
                "completedByHouseholdMemberId": actor, "submittedAt": now, "requiredApprovalCount": original.occurrence!.requiredApprovalCount,
                "status": finalized ? "APPROVED" : "AWAITING_APPROVAL", "resolvedAt": finalized ? now as Any : NSNull(),
                "version": 0, "approvals": []], at: 0)
        case .approve(let completionId), .reject(let completionId):
            let approved: Bool = if case .approve = action { true } else { false }
            guard (approved ? original.actions?.canApprove : original.actions?.canReject) == true,
                  let index = submissions.firstIndex(where: { ($0["choreCompletionId"] as? String) == completionId.uuidString }) else {
                throw APIError.http(statusCode: 403, problem: nil)
            }
            var submission = submissions[index]
            var reviews = submission["approvals"] as? [[String: Any]] ?? []
            reviews.append(["choreApprovalId": UUID().uuidString, "reviewedByHouseholdMemberId": actor,
                            "decision": approved ? "APPROVED" : "REJECTED", "reviewedAt": now])
            submission["approvals"] = reviews
            finalized = approved && reviews.filter { ($0["decision"] as? String) == "APPROVED" }.count >= original.pendingCompletion!.requiredApprovalCount
            if finalized || !approved {
                submission["status"] = finalized ? "APPROVED" : "REJECTED"
                submission["resolvedAt"] = now
                current!["occurrenceStatus"] = finalized ? "COMPLETED" : "PENDING"
                current!["version"] = original.occurrence!.version + 1
            }
            submission["version"] = original.pendingCompletion!.version + 1
            submissions[index] = submission
        }
        if let current, let index = history.firstIndex(where: { ($0["choreOccurrenceId"] as? String) == (current["choreOccurrenceId"] as? String) }) {
            history[index] = current
        }
        if finalized && (original.pattern == .fixed || original.pattern == .afterCompletion) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: original.schedule!.timeZoneIdentifier)!
            let baseline = original.pattern == .fixed ? (ChoreTimestamp.decode(original.occurrence?.scheduledAt) ?? .now) : .now
            let next = calendar.date(byAdding: .day, value: original.schedule!.recurrenceInterval, to: max(baseline, .now))!
            current = newOccurrence(scheduled: ChoreTimestamp.encode(next))
            history.insert(current!, at: 0)
        }
        json["occurrence"] = current
        json["occurrences"] = history
        json["completions"] = submissions
        json["version"] = original.version + 1
        var response = try JSONDecoder().decode(ChoreResponse.self, from: JSONSerialization.data(withJSONObject: json))
        response = withActions(response)
        responses.removeAll { $0.id == id }
        responses.append(response)
        return response
    }
}

nonisolated struct ChoreUITestUserService: CurrentUserServiceProtocol {
    func fetchCurrentUser() async throws -> CurrentUser {
        await CurrentUser(id: ChoreUITestFixture.userId, email: "alex@example.com", firstName: "Alex", lastName: "Example")
    }
}
#endif
