@MainActor
protocol HouseholdRepositoryProtocol {
    func create(_ creation: HouseholdCreation) throws
}
