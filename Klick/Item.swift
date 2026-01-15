//
//  Item.swift
//  Klick
//
//  Created by Tobias Bleckert on 2026-01-16.
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
