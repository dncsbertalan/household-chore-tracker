import Foundation

/// API redirects are surfaced as HTTP errors instead of forwarding credentials or replaying POSTs.
final class APIRedirectPolicy: NSObject, URLSessionTaskDelegate,
    Sendable
{
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
