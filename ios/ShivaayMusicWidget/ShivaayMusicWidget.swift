import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), songTitle: "Song Title", songArtist: "Artist Name", isPlaying: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let songInfo = SongInfo(
            title: "Current Song",
            artist: "Current Artist",
            albumArtUrl: nil,
            isPlaying: true,
            progress: 0.5,
            duration: 180,
            currentTime: 90
        )
        let entry = SimpleEntry(date: Date(), songInfo: songInfo)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Retrieve current song information from shared data
        let songInfo = SharedData.shared.getCurrentSong()
        
        let entry = SimpleEntry(
            date: Date(),
            songInfo: songInfo
        )
        
        // Create timeline with current entry
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func getCurrentSongInfo() -> (title: String, artist: String, isPlaying: Bool) {
        let songInfo = SharedData.shared.getCurrentSong()
        return (title: songInfo.title, artist: songInfo.artist, isPlaying: songInfo.isPlaying)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let songInfo: SongInfo
    
    var songTitle: String { songInfo.title }
    var songArtist: String { songInfo.artist }
    var isPlaying: Bool { songInfo.isPlaying }
}

struct ShivaayMusicWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(.white)
                    .font(.title)
                
                Spacer()
                
                if entry.isPlaying {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                } else {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            
            Text(entry.songTitle)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(entry.songArtist)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * 0.5) // Placeholder progress
                            .animation(.linear, value: 0.5)
                    )
            }
            .frame(height: 4)
            .cornerRadius(2)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

@main
struct ShivaayMusicWidget: Widget {
    let kind: String = "ShivaayMusicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ShivaayMusicWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Shivaay Music")
        .description("Control your music playback from the home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ShivaayMusicWidget_Previews: PreviewProvider {
    static var previews: some View {
        let songInfo = SongInfo(
            title: "Song Title",
            artist: "Artist Name",
            albumArtUrl: nil,
            isPlaying: true,
            progress: 0.5,
            duration: 180,
            currentTime: 90
        )
        ShivaayMusicWidgetEntryView(entry: SimpleEntry(date: Date(), songInfo: songInfo))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}