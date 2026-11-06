//
//  UserInfo.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 06..
//

import Foundation

nonisolated struct UserInfo: Codable, Sendable, Identifiable {
    let userId: UUID
    let email: String
    let firstName: String
    let lastName: String

    var id: UUID { userId }
}
