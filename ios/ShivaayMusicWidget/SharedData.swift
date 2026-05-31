import Foundation
import WidgetKit

// Shared data structure for song information
struct SongInfo: Codable {
    let title: String
    let artist: String
    let albumArtUrl: String?
    let isPlaying: Bool
    let progress: Double // 0.0 to 1.0
    let duration: TimeInterval
    let currentTime: TimeInterval
    
    static let placeholder = SongInfo(
        title: "No Song Playing",
        artist: "",
        albumArtUrl: nil,
        isPlaying: false,
        progress: 0.0,
        duration: 0,
        currentTime: 0
    )
}

// Utility class for sharing data between app and widget
class SharedData {
    static let shared = SharedData()
    
    private let userDefaults: UserDefaults
    private let suiteName = "group.com.shivaaymusic.shared"
    
    private init() {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to create UserDefaults with suite name: \(suiteName)")
        }
        self.userDefaults = userDefaults
    }
    
    // Save current song information
    func saveCurrentSong(_ songInfo: SongInfo) {
        do {
            let data = try JSONEncoder().encode(songInfo)
            userDefaults.set(data, forKey: "currentSong")
            userDefaults.synchronize()
            
            // Reload timelines to update widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "ShivaayMusicWidget")
        } catch {
            print("Error encoding song info: \(error)")
        }
    }
    
    // Retrieve current song information
    func getCurrentSong() -> SongInfo {
        guard let data = userDefaults.data(forKey: "currentSong") else {
            return SongInfo.placeholder
        }
        
        do {
            return try JSONDecoder().decode(SongInfo.self, from: data)
        } catch {
            print("Error decoding song info: \(error)")
            return SongInfo.placeholder
        }
    }
    
    // Clear current song information
    func clearCurrentSong() {
        userDefaults.removeObject(forKey: "currentSong")
        userDefaults.synchronize()
        
        // Reload timelines to update widgets
        WidgetCenter.shared.reloadTimelines(ofKind: "ShivaayMusicWidget")
    }
}