//
//  APIError.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

nonisolated enum APIError: LocalizedError {
    case invalidResponse
    case decodingFailed(Error)
    case unauthorized           // 401
    case forbidden              // 403
    case notFound               // 404
    case conflict               // 409
    case rateLimited(retryAfter: Int?) // 429
    case serverError(Int)       // 500-599
    case clientError(Int, String?) // 400, 422, etc.
    case noInternet
    case timeout

    static func from(statusCode: Int, data: Data) -> APIError {
        let message = try? JSONDecoder().decode(ErrorBody.self, from: data).message

        switch statusCode {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 409: return .conflict
        case 429: return .rateLimited(retryAfter: nil)
        case 400, 422: return .clientError(statusCode, message)
        case 500...599: return .serverError(statusCode)
        default: return .clientError(statusCode, message)
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response."
        case .decodingFailed: return "Failed to parse server data."
        case .unauthorized: return "Session expired. Please sign in again."
        case .forbidden: return "You do not have permission."
        case .notFound: return "The requested resource was not found."
        case .conflict: return "A conflict occurred. Try again."
        case .rateLimited: return "Too many requests. Please wait."
        case .serverError(let code): return "Server error (\(code)). Try again later."
        case .clientError(_, let msg): return msg ?? "Something went wrong."
        case .noInternet: return "No internet connection."
        case .timeout: return "Request timed out."
        }
    }
}

nonisolated struct ErrorBody: Decodable {
    let message: String?
}

/*import Foundation

nonisolated enum APIError: LocalizedError {
    case invalidResponse
    case decodingFailed(Error)

    case unauthorized(ProblemDetail?)   // 401
    case forbidden(ProblemDetail?)      // 403
    case notFound(ProblemDetail?)       // 404
    case conflict(ProblemDetail?)       // 409
    case rateLimited(retryAfter: Int?, ProblemDetail?)  // 429
    case serverError(Int, ProblemDetail?)   //500-599
    case clientError(Int, ProblemDetail?)   // 400, 422, etc.

    case noInternet
    case timeout

    static func from(statusCode: Int, data: Data, retryAfter: Int? = nil) -> APIError {
        let problem = try? JSONDecoder().decode(ProblemDetail.self, from: data)

        switch statusCode {
        case 401: return .unauthorized(problem)
        case 403: return .forbidden(problem)
        case 404: return .notFound(problem)
        case 409: return .conflict(problem)
        case 429: return .rateLimited(retryAfter: retryAfter, problem)
        case 500...599: return .serverError(statusCode, problem)
        default: return .clientError(statusCode, problem)
        }
    }

    var problem: ProblemDetail? {
        switch self {
        case .unauthorized(let p),
             .forbidden(let p),
             .notFound(let p),
             .conflict(let p),
             .rateLimited(_, let p),
             .serverError(_, let p),
             .clientError(_, let p):
            return p

        default:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return String(localized: "network.error.invalidResponse")
        case .decodingFailed: return String(localized: "network.error.decoding")
        case .unauthorized: return String(localized: "network.error.unauthorized")
        case .forbidden: return String(localized: "network.error.forbidden")
        case .notFound: return String(localized: "network.error.notFound")
        case .conflict: return String(localized: "network.error.conflict")
        case .rateLimited: return String(localized: "network.error.rateLimited")
        case .serverError: return String(localized: "network.error.server")
        case .clientError(_, let problem): return problem?.detail ?? String(localized: "network.error.generic")
        case .noInternet: return String(localized: "network.error.noInternet")
        case .timeout: return String(localized: "network.error.timeout")
        }
    }
}*/
