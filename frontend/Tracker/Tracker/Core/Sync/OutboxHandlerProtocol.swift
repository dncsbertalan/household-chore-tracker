/// Features supply delivery and reconciliation; the queue never decodes feature payloads.
@MainActor
protocol OutboxHandlerProtocol {
    var entityType: OutboxEntityType { get }
    var action: OutboxAction { get }
    func send(_ operation: QueuedOutboxOperation) async throws
        -> any OutboxReconciliationProtocol
}
