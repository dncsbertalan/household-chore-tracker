//
//  PermissionResponse.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//


nonisolated struct PermissionResponse: Decodable, Identifiable, Sendable {
    let permissionId: Int64
    let name: String
    let description: String?

    var id: Int64 { permissionId }
}
