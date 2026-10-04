//
//  User.swift
//  Track
//
//  Created by Dancs Bertalan on 2026. 10. 04..
//

import Foundation

struct User: Equatable, Sendable {
    let id: UUID
    var displayName: String
    var email: String
}
