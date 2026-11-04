#if DEBUG
import Foundation

@MainActor
enum ChoreUITestFixture {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("--ui-test-chores") }
    static let userId = UUID(uuidString: "1A460DB1-9970-48EA-A93B-C08A66FA6701")!
    static let householdId = UUID(uuidString: "1A460DB1-9970-48EA-A93B-C08A66FA6702")!

    static func household() -> HouseholdResponse {
        let grants: [HouseholdPermission] = ProcessInfo.processInfo.arguments.contains("--ui-test-no-edit-permission")
            ? [.memberView] : [.choreCreate, .choreUpdate, .choreAssignMember, .memberView, .roleView]
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
    private var responses: [ChoreResponse]

    init() {
        let memberId = home.members[0].householdMemberId
        responses = ChoreCreationPattern.allCases.map { ChoreUITestFixture.chore(pattern: $0, memberId: memberId) }
        responses.append(ChoreUITestFixture.chore(pattern: .once, memberId: memberId, completed: true))
    }
    func households(accountId: UUID) async throws -> [HouseholdResponse] { [home] }
    func household(id: UUID, accountId: UUID) async throws -> HouseholdResponse { home }
    func create(_ creation: HouseholdCreation) async throws -> HouseholdResponse { throw APIError.invalidResponse }
    func create(_ creation: ChoreCreation) async throws -> ChoreResponse { throw APIError.invalidResponse }
    func chores(accountId: UUID, householdId: UUID?) async throws -> [ChoreResponse] { responses }
    func chore(id: UUID, accountId: UUID) async throws -> ChoreResponse {
        guard let response = responses.first(where: { $0.id == id }) else { throw APIError.invalidResponse }
        return response
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

nonisolated struct ChoreUITestUserService: CurrentUserServiceProtocol {
    func fetchCurrentUser() async throws -> CurrentUser {
        await CurrentUser(id: ChoreUITestFixture.userId, email: "alex@example.com", firstName: "Alex", lastName: "Example")
    }
}
#endif
