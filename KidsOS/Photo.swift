//
//  Photo.swift
//  KidsOS
//
//  Created by Tobias Bleckert on 2026-01-16.
//

import Foundation
import SwiftData

@Model
final class Photo {
    var id: UUID
    var filename: String
    var timestamp: Date
    
    init(filename: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.filename = filename
        self.timestamp = timestamp
    }
    
    var fileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(filename)
    }
}
