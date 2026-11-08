//
//  CurrentUser.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

nonisolated struct CurrentUser: Decodable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
}
