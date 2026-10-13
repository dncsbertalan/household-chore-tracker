import Foundation

nonisolated enum APIRetryPolicy: Sendable {
    case none
    /// At most three GET attempts with exponential backoff and jitter. Never replays mutations.
    case transientReads

    func delay(afterAttempt attempt: Int, method: HTTPMethod, error: Error) -> TimeInterval? {
        guard case .transientReads = self, method == .get, attempt < 3,
              let error = error as? APIError else { return nil }
        switch error {
        case .http(let status, _) where [500, 502, 503, 504].contains(status): break
        case .transport(.timedOut), .transport(.networkConnectionLost): break
        default: return nil
        }
        return 0.5 * pow(2, Double(attempt - 1)) + Double.random(in: 0...0.25)
    }
}
