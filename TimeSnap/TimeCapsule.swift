import Foundation
import SwiftUI

struct TimeCapsule: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var unlockDate: Date
    var includeTime: Bool
    var mediaItems: [MediaItem]
    var createdAt: Date
    var color: Color
    var sharedWith: [String] // Array of email addresses
    var isShared: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, unlockDate, includeTime, mediaItems, createdAt
        case colorRed, colorGreen, colorBlue
        case sharedWith, isShared
    }
    
    init(id: UUID = UUID(), title: String, description: String, unlockDate: Date, includeTime: Bool = false, mediaItems: [MediaItem] = [], createdAt: Date = Date(), color: Color = Color(red: 0.8, green: 0.6, blue: 0.4), sharedWith: [String] = [], isShared: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.unlockDate = unlockDate
        self.includeTime = includeTime
        self.mediaItems = mediaItems
        self.createdAt = createdAt
        self.color = color
        self.sharedWith = sharedWith
        self.isShared = isShared
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        unlockDate = try container.decode(Date.self, forKey: .unlockDate)
        includeTime = try container.decode(Bool.self, forKey: .includeTime)
        mediaItems = try container.decode([MediaItem].self, forKey: .mediaItems)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        sharedWith = try container.decode([String].self, forKey: .sharedWith)
        isShared = try container.decode(Bool.self, forKey: .isShared)
        
        let red = try container.decode(Double.self, forKey: .colorRed)
        let green = try container.decode(Double.self, forKey: .colorGreen)
        let blue = try container.decode(Double.self, forKey: .colorBlue)
        color = Color(red: red, green: green, blue: blue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(unlockDate, forKey: .unlockDate)
        try container.encode(includeTime, forKey: .includeTime)
        try container.encode(mediaItems, forKey: .mediaItems)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(sharedWith, forKey: .sharedWith)
        try container.encode(isShared, forKey: .isShared)
        
        // Extract RGB components from the color
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try container.encode(Double(red), forKey: .colorRed)
        try container.encode(Double(green), forKey: .colorGreen)
        try container.encode(Double(blue), forKey: .colorBlue)
    }
}

struct MediaItem: Identifiable, Codable {
    let id: UUID
    var type: MediaType
    var url: URL
    var thumbnailURL: URL?
    
    init(id: UUID = UUID(), type: MediaType, url: URL, thumbnailURL: URL? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.thumbnailURL = thumbnailURL
    }
}

enum MediaType: String, Codable {
    case photo
    case video
    case message
} 