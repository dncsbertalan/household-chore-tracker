nonisolated struct CSRFResponse: Decodable, Sendable {
    let token: String
    let headerName: String
}
