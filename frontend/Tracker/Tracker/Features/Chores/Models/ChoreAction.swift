import Foundation

nonisolated enum ChoreAction: Equatable, Sendable {
    case start
    case complete(UUID)
    case approve(UUID)
    case reject(UUID)

    var path: String {
        switch self {
        case .start: "occurrences"
        case .complete(let id): "occurrences/\(id)/complete"
        case .approve(let id): "completions/\(id)/approve"
        case .reject(let id): "completions/\(id)/reject"
        }
    }
}

nonisolated struct ChoreActionRequest: Codable, Equatable, Sendable {
    let version: Int64
    let occurrenceVersion: Int64?
    let completionVersion: Int64?
}
