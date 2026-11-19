//
//  ChoreRecurrenceUnit.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 19..
//

import Foundation

nonisolated enum ChoreRecurrenceUnit: String, Codable, CaseIterable, Identifiable {
    case hour = "HOUR"
    case day = "DAY"
    case week = "WEEK"
    case month = "MONTH"
    case year = "YEAR"
    
    var id: String { rawValue }
    
    var label: String { rawValue.lowercased().capitalized }
}
