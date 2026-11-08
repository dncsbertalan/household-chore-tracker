//
//  AppLanguage.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case hungarian = "hu"
    
    static let storageKey = "app.language"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: "System Default"
        case .english: "English"
        case .hungarian: "Magyar"
        }
    }
    
    var locale: Locale {
        switch self {
        case .system: .autoupdatingCurrent
        case .english: Locale(identifier: "en")
        case .hungarian: Locale(identifier: "hu")
        }
    }
}
