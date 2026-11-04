import Foundation
import Observation

@Observable
@MainActor
final class ChoresRouter {
    var path: [ChoreRoute] = []
    var sheet: ChoresSheet?
}

enum ChoreRoute: Hashable {
    case detail(choreId: UUID)
}
