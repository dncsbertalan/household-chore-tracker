import Foundation
import SwiftData

/// A durable command awaiting acknowledgement. Intentionally independent of entity delete cascades.
@Model
final class OutboxRecord {
    @Attribute(.unique) private(set) var commandId: UUID
    private(set) var accountId: UUID
    private(set) var aggregateId: UUID
    private(set) var commandType: String
    private(set) var payloadVersion: Int
    private(set) var payload: Data
    private(set) var createdAt: Date
    
    init(command: OutboxCommand) {
        commandId = command.id
        accountId = command.accountId
        aggregateId = command.aggregateId
        commandType = command.commandType.rawValue
        payloadVersion = command.payloadVersion
        payload = command.payload
        createdAt = command.createdAt
    }
    
    var command: OutboxCommand {
        get throws {
            guard let type = OutboxCommandType(rawValue: commandType) else {
                throw OutboxRecordError.unsupportedCommandType(commandType)
            }
            return OutboxCommand(id: commandId, accountId: accountId, aggregateId: aggregateId,
                                 commandType: type, payloadVersion: payloadVersion,
                                 payload: payload, createdAt: createdAt)
        }
    }
}

nonisolated enum OutboxRecordError: Error, Equatable {
    case unsupportedCommandType(String)
}
