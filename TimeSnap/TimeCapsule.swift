import Foundation

struct TimeCapsule: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var unlockDate: Date
    var includeTime: Bool
    var mediaItems: [MediaItem]
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, description: String, unlockDate: Date, includeTime: Bool = false, mediaItems: [MediaItem] = [], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.unlockDate = unlockDate
        self.includeTime = includeTime
        self.mediaItems = mediaItems
        self.createdAt = createdAt
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