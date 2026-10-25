import Foundation

nonisolated struct URLSessionTransport: HTTPTransportProtocol {
    let session: URLSession

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
