import Foundation

nonisolated struct UpdateMemberNicknameRequest: Encodable, Equatable, Sendable {
    let nickname: String?
    let version: Int64
}
