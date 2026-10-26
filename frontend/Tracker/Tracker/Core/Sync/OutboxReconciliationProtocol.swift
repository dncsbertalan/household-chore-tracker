import SwiftData

@MainActor
protocol OutboxReconciliationProtocol {
    func apply(in context: ModelContext) throws
}
