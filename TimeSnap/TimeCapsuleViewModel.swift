import Foundation
import SwiftUI

class TimeCapsuleViewModel: ObservableObject {
    @Published var timeCapsules: [TimeCapsule] = []
    private let saveKey = "timeCapsules"
    
    init() {
        loadTimeCapsules()
    }
    
    func addTimeCapsule(_ capsule: TimeCapsule) {
        timeCapsules.append(capsule)
        saveTimeCapsules()
    }
    
    func deleteTimeCapsule(_ capsule: TimeCapsule) {
        if let index = timeCapsules.firstIndex(where: { $0.id == capsule.id }) {
            timeCapsules.remove(at: index)
            saveTimeCapsules()
        }
    }
    
    func shareCapsule(capsule: TimeCapsule, with email: String) {
        if let index = timeCapsules.firstIndex(where: { $0.id == capsule.id }) {
            var updatedCapsule = capsule
            if !updatedCapsule.sharedWith.contains(email) {
                updatedCapsule.sharedWith.append(email)
                updatedCapsule.isShared = true
                timeCapsules[index] = updatedCapsule
                saveTimeCapsules()
            }
        }
    }
    
    func removeShare(capsule: TimeCapsule, email: String) {
        if let index = timeCapsules.firstIndex(where: { $0.id == capsule.id }) {
            var updatedCapsule = capsule
            updatedCapsule.sharedWith.removeAll { $0 == email }
            if updatedCapsule.sharedWith.isEmpty {
                updatedCapsule.isShared = false
            }
            timeCapsules[index] = updatedCapsule
            saveTimeCapsules()
        }
    }
    
    private func saveTimeCapsules() {
        if let encoded = try? JSONEncoder().encode(timeCapsules) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadTimeCapsules() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TimeCapsule].self, from: data) {
            timeCapsules = decoded
        }
    }
} 