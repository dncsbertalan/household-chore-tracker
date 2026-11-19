//
//  ChoreCreationPattern.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 19..
//

import Foundation

nonisolated enum ChoreCreationPattern: String, Codable, CaseIterable, Identifiable {
    case once = "ONCE"
    case fixed = "FIXED"
    case afterCompletion = "AFTER_COMPLETION"
    case onDemand = "ON_DEMAND"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .once: "Once"
        case .fixed: "Fixed schedule"
        case .afterCompletion: "After completion"
        case .onDemand: "On demand"
        }
    }
    
    var isRecurring: Bool { self == .fixed || self == .afterCompletion }
}
