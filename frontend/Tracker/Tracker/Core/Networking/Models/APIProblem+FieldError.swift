import Foundation

extension APIProblem {
    nonisolated struct FieldError: Decodable, Sendable {
        let field: String
        let message: String
    }
}
