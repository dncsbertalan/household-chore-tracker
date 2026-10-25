import Foundation

/// Matches Spring's Problem Details responses, including field validation errors.
nonisolated struct APIProblem: Decodable, Sendable {
    let type: String?
    let title: String?
    let status: Int?
    let detail: String?
    let instance: String?
    let errors: [FieldError]?
}
