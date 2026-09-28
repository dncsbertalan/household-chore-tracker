//
//  Item.swift
//  Track
//
//  Created by Dancs Bertalan on 2026. 09. 28..
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
