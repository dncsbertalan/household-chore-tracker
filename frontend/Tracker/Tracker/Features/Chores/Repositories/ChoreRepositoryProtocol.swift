@MainActor
protocol ChoreRepositoryProtocol {
    func create(_ creation: ChoreCreation) throws
}
