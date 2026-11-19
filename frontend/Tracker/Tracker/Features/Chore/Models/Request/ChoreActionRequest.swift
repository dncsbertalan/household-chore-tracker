import Foundation

nonisolated struct ChoreActionRequest: Encodable, Sendable {
    let version: Int64
    let occurrenceVersion: Int64?
    let completionVersion: Int64?
}

nonisolated enum ChoreAction: Sendable {
    case complete(UUID)
    case approve(UUID)
    case reject(UUID)

    var path: String {
        switch self {
        case .complete(let id): "occurrences/\(id)/complete"
        case .approve(let id): "completions/\(id)/approve"
        case .reject(let id): "completions/\(id)/reject"
        }
    }
}
