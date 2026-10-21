/// TODO: decide what kind of actor is required here
@MainActor
protocol HouseholdRepository {
    func create() async throws
    func save() async throws
}
