import Foundation

/// Matches Spring's Problem Details responses, including field validation errors.
nonisolated struct APIProblem: Decodable, Sendable {
    let type: String?
    let title: String?
    let status: Int?
    let detail: String?
    let instance: String?
    let errors: [FieldError]?

    struct FieldError: Decodable, Sendable {
        let field: String
        let message: String
    }
}

nonisolated enum APIError: Error, LocalizedError, Sendable {
    case invalidConfiguration
    case invalidEndpoint
    case encodingFailed
    case invalidResponse
    case http(statusCode: Int, problem: APIProblem?)
    case decodingFailed
    case transport(URLError.Code)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return AppLocalization.string("network.error.configuration")
        case .invalidEndpoint:
            return AppLocalization.string("network.error.endpoint")
        case .encodingFailed:
            return AppLocalization.string("network.error.encoding")
        case .invalidResponse:
            return AppLocalization.string("network.error.response")
        case .http(let statusCode, _):
            // Feature services can inspect the problem; never display or log raw bodies here.
            return AppLocalization.string(
                "network.error.http",
                defaultValue: "The request failed (HTTP \(statusCode))."
            )
        case .decodingFailed:
            return AppLocalization.string("network.error.decoding")
        case .transport(.notConnectedToInternet):
            return AppLocalization.string("network.error.offline")
        case .transport(.timedOut):
            return AppLocalization.string("network.error.timeout")
        case .transport:
            return AppLocalization.string("network.error.connection")
        }
    }
}
