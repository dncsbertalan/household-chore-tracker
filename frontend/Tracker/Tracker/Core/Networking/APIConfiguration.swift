import Foundation

nonisolated struct APIConfiguration: Sendable {
    let baseURL: URL

    init(baseURL: URL) throws {
        guard let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil else {
            throw APIError.invalidConfiguration
        }
        var allowed = components.scheme == "https"
        #if DEBUG
        // Plain HTTP is restricted to local development, never production hosts.
        allowed = allowed || (components.scheme == "http" &&
            ["localhost", "127.0.0.1", "::1", "[::1]"].contains(host))
        #endif
        guard allowed else { throw APIError.invalidConfiguration }
        self.baseURL = baseURL
    }

    /// Override API_BASE_URL in the target's Info.plist for devices or hosted environments.
    static func from(bundle: Bundle = .main) throws -> APIConfiguration {
        if let value = bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            guard let url = URL(string: value) else { throw APIError.invalidConfiguration }
            return try APIConfiguration(baseURL: url)
        }
        #if DEBUG
        return try APIConfiguration(baseURL: URL(string: "http://localhost:8080/api/v1")!)
        #else
        throw APIError.invalidConfiguration
        #endif
    }
}
