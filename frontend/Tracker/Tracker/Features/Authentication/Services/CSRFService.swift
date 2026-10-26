import Foundation

nonisolated struct CSRFService: Sendable {
    let client: any APIClientProtocol

    func headers() async throws -> [String: String] {
        let csrf = try await client.request(endpoint: "auth/csrf", as: CSRFResponse.self)
        guard !csrf.token.isEmpty, !csrf.headerName.isEmpty,
              csrf.headerName.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }),
              !csrf.token.contains("\r"), !csrf.token.contains("\n") else {
            throw APIError.invalidResponse
        }
        return [csrf.headerName: csrf.token]
    }
}
