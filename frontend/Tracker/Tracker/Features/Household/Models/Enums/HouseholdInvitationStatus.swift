//
//  HouseholdInvitationStatus.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation
import SwiftUI

nonisolated enum HouseholdInvitationStatus: String, Codable, CaseIterable, Identifiable, Sendable {

    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case declined = "DECLINED"
    case revoked = "REVOKED"
    case expired = "EXPIRED"
    
    var id: String { rawValue }
    
    var label: LocalizedStringKey {
        switch self {
        case .pending: "household.invitation.status.pending"
        case .accepted: "household.invitation.status.accepted"
        case .declined: "household.invitation.status.declined"
        case .revoked: "household.invitation.status.revoked"
        case .expired: "household.invitation.status.expired"
        }
    }
}
