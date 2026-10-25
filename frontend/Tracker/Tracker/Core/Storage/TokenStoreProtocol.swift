nonisolated protocol TokenStoreProtocol: Sendable {
    func save(_ tokens: StoredTokens) async throws
    func load() async throws -> StoredTokens?
    func clear() async throws
    func replace(_ tokens: StoredTokens, ifMatching expected: StoredTokens)
        async throws -> Bool
    func clear(ifMatching expected: StoredTokens) async throws -> Bool
}
