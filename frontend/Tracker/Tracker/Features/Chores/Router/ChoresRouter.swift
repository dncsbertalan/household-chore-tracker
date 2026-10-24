import Observation

@Observable
@MainActor
final class ChoresRouter {
    var sheet: ChoresSheet?
}
