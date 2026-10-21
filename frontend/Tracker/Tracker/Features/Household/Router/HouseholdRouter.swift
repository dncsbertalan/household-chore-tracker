import Observation

@Observable
@MainActor
final class HouseholdRouter {
    var path: [HouseholdRoute] = []
    var sheet: HouseholdSheet?

    func navigate(to route: HouseholdRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
