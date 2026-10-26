import Foundation

@MainActor
struct OutboxDispatcher {
    let handlers: [any OutboxHandlerProtocol]

    func send(_ operation: QueuedOutboxOperation) async throws
        -> any OutboxReconciliationProtocol
    {
        guard
            let handler = handlers.first(where: {
                $0.entityType.rawValue == operation.entityType
                    && $0.action.rawValue == operation.action
            })
        else { throw OutboxError.unsupportedOperation }
        return try await handler.send(operation)
    }
}
