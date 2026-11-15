import XCTest
@testable import Tracker

final class TrackerTests: XCTestCase {
    @MainActor
    func testLoginPersistsTokensAndSuppliesCSRFWithoutBearer() async throws {
        let store = MemoryTokenStore()
        let service = makeService(store: store)
        AuthURLProtocol.handler = { request in
            if request.url?.path == "/api/v1/auth/csrf" {
                XCTAssertEqual(request.httpMethod, "GET")
                return (200, #"{"headerName":"X-CSRF-TOKEN","token":"csrf-value"}"#)
            }
            XCTAssertEqual(request.url?.path, "/api/v1/auth/login")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-CSRF-TOKEN"), "csrf-value")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let body = try Self.body(request)
            XCTAssertEqual(body["email"], "person@example.com")
            XCTAssertEqual(body["password"], "a-long-password")
            return (200, #"{"accessToken":"access","refreshToken":"refresh","tokenType":"Bearer","expiresIn":900,"refreshExpiresIn":2592000}"#)
        }
        let tokens = try await service.login(email: "person@example.com", password: "a-long-password")
        let saved = try await store.load()
        XCTAssertEqual(saved, tokens)
        XCTAssertGreaterThan(tokens.accessExpiresAt, Date())
    }

    @MainActor
    func testRegistrationUsesCamelCaseAndDoesNotSaveSession() async throws {
        let store = MemoryTokenStore()
        let service = makeService(store: store)
        AuthURLProtocol.handler = { request in
            if request.url?.path == "/api/v1/auth/csrf" {
                return (200, #"{"headerName":"X-CSRF-TOKEN","token":"csrf-value"}"#)
            }
            XCTAssertEqual(request.url?.path, "/api/v1/auth/register")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-CSRF-TOKEN"), "csrf-value")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            let body = try Self.body(request)
            XCTAssertEqual(body["firstName"], "Test")
            XCTAssertEqual(body["lastName"], "User")
            XCTAssertNil(body["first_name"])
            return (201, #"{"id":"f1111111-1111-1111-1111-111111111111","email":"person@example.com","firstName":"Test","lastName":"User"}"#)
        }
        let user = try await service.register(email: "person@example.com", password: "a-long-password", firstName: "Test", lastName: "User")
        XCTAssertEqual(user.firstName, "Test")
        let saved = try await store.load()
        XCTAssertNil(saved)
    }

    @MainActor
    func testFailedLoginDoesNotSaveTokens() async throws {
        let store = MemoryTokenStore()
        let service = makeService(store: store)
        AuthURLProtocol.handler = { request in
            if request.url?.path == "/api/v1/auth/csrf" {
                return (200, #"{"headerName":"X-CSRF-TOKEN","token":"csrf-value"}"#)
            }
            return (401, "")
        }
        do {
            _ = try await service.login(email: "person@example.com", password: "wrong")
            XCTFail("Expected unauthorized")
        } catch APIError.unauthorized {}
        let saved = try await store.load()
        XCTAssertNil(saved)
    }

    @MainActor
    private func makeService(store: MemoryTokenStore) -> AuthenticationService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthURLProtocol.self]
        let api = APIClient(baseURL: URL(string: "https://tracker.test/api/v1")!, session: URLSession(configuration: configuration), tokenStore: store)
        return AuthenticationService(apiClient: api, tokenStore: store)
    }

    nonisolated private static func body(_ request: URLRequest) throws -> [String: String] {
        var data = request.httpBody ?? Data()
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(contentsOf: buffer.prefix(count))
            }
        }
        return try JSONDecoder().decode([String: String].self, from: data)
    }
}

private actor MemoryTokenStore: TokenStoreProtocol {
    var tokens: StoredTokens?
    func save(_ tokens: StoredTokens) async throws { self.tokens = tokens }
    func load() async throws -> StoredTokens? { tokens }
    func clear() async throws { tokens = nil }
}

private final class AuthURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Int, String))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, body) = try Self.handler!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}
