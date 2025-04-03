import Foundation
import SwiftUI

class TimeCapsuleViewModel: ObservableObject {
    @Published var timeCapsules: [TimeCapsule] = []
    private let saveKey = "timeCapsules"
    
    init() {
        loadTimeCapsules()
    }
    
    func addTimeCapsule(_ timeCapsule: TimeCapsule) {
        timeCapsules.append(timeCapsule)
        saveTimeCapsules()
    }
    
    func deleteTimeCapsule(_ timeCapsule: TimeCapsule) {
        // Delete associated media files
        for mediaItem in timeCapsule.mediaItems {
            try? FileManager.default.removeItem(at: mediaItem.url)
        }
        
        timeCapsules.removeAll { $0.id == timeCapsule.id }
        saveTimeCapsules()
    }
    
    private func saveTimeCapsules() {
        do {
            let data = try JSONEncoder().encode(timeCapsules)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Error saving time capsules: \(error)")
        }
    }
    
    private func loadTimeCapsules() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            timeCapsules = try JSONDecoder().decode([TimeCapsule].self, from: data)
        } catch {
            print("Error loading time capsules: \(error)")
        }
    }
} 