import Foundation

nonisolated enum ChoreEnumCoding {
    /// Read legacy local data and queued responses while all new encoding uses uppercase raw values.
    static func decode<Value: RawRepresentable>(
        _ type: Value.Type, from decoder: any Decoder
    ) throws -> Value where Value.RawValue == String {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        let normalized: String
        switch rawValue {
        case "afterCompletion": normalized = "AFTER_COMPLETION"
        case "onDemand": normalized = "ON_DEMAND"
        case "inProgress": normalized = "IN_PROGRESS"
        case "awaitingApproval": normalized = "AWAITING_APPROVAL"
        default: normalized = rawValue.uppercased()
        }
        guard let value = Value(rawValue: normalized) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown chore enum value: \(rawValue)")
        }
        return value
    }
}
