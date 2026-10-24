import Foundation
import SwiftData

enum OutboxStore {
    static func enqueue(
        _ operation: OutboxOperation,
        in context: ModelContext
    ) {
        context.insert(OutboxEntry(operation))
    }
}
