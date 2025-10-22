//
//  EmotiPlayWidget.swift
//  EmotiPlayWidget
//
//  Fixed Timeline Provider - removes Context() error
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(
            date: Date(),
            mood: "Happy",
            emoji: "😊",
            playlistName: "Happy Vibes",
            confidence: 85,
            recentPlaylists: []
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> ()) {
        let entry = loadLatestMood()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadLatestMood()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadLatestMood() -> MoodEntry {
        // REMOVED: The problematic placeholder(in: Context()) call
        
        // Use guard-let instead to safely unwrap sharedDefaults
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourteam.emotionplay") else {
            // Return default entry if App Group isn't set up
            return MoodEntry(
                date: Date(),
                mood: "Unknown",
                emoji: "🎵",
                playlistName: "No playlist yet",
                confidence: 0,
                recentPlaylists: []
            )
        }
        
        let mood = sharedDefaults.string(forKey: "latestMood") ?? "Unknown"
        let emoji = sharedDefaults.string(forKey: "latestEmoji") ?? "🎵"
        let playlist = sharedDefaults.string(forKey: "latestPlaylist") ?? "No playlist yet"
        let confidence = sharedDefaults.integer(forKey: "latestConfidence")
        
        // Load recent playlists
        var recentPlaylists: [RecentPlaylist] = []
        if let data = sharedDefaults.data(forKey: "recentPlaylists"),
           let decoded = try? JSONDecoder().decode([RecentPlaylist].self, from: data) {
            recentPlaylists = decoded
        }
        
        let hasData = mood != "Unknown" && emoji != "🎵"
        
        return MoodEntry(
            date: Date(),
            mood: hasData ? mood : "No recent playlist detected",
            emoji: hasData ? emoji : "📷",
            playlistName: hasData ? playlist : "Take a photo to start",
            confidence: confidence,
            recentPlaylists: recentPlaylists
        )
    }
}

// MARK: - Models
struct MoodEntry: TimelineEntry {
    let date: Date
    let mood: String
    let emoji: String
    let playlistName: String
    let confidence: Int
    let recentPlaylists: [RecentPlaylist]
}

struct RecentPlaylist: Codable, Identifiable {
    let id = UUID()
    let mood: String
    let emoji: String
    let name: String
    let date: Date
}

// MARK: - Widget Entry View
struct EmotiPlayWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
    
    
    
    
    // MARK: - Small Widget
    struct SmallWidgetView: View {
        let entry: MoodEntry
        
        var body: some View {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.green.opacity(0.6), Color.black.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 8) {
                    // Emoji
                    Text(entry.emoji)
                        .font(.system(size: 50))
                    
                    // Mood
                    Text(entry.mood)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Confidence badge
                    if entry.confidence > 0 {
                        Text("\(entry.confidence)%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Home button
                    Link(destination: URL(string: "emotionplay://home")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                            Text("New")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Medium Widget
    struct MediumWidgetView: View {
        let entry: MoodEntry
        
        var body: some View {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.green.opacity(0.6), Color.black.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(ContainerRelativeShape())
                
                HStack(spacing: 16) {
                    // Left side - Current mood
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.emoji)
                            .font(.system(size: 60))
                        
                        Text(entry.mood)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text(entry.playlistName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                        
                        if entry.confidence > 0 {
                            Text("\(entry.confidence)% confident")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Home button
                        Link(destination: URL(string: "emotionplay://home")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right side - Recent playlists
                    if !entry.recentPlaylists.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recent")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            
                            ForEach(entry.recentPlaylists.prefix(3)) { playlist in
                                HStack(spacing: 6) {
                                    Text(playlist.emoji)
                                        .font(.caption)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(playlist.mood)
                                            .font(.caption2.bold())
                                            .foregroundColor(.white)
                                        
                                        Text(playlist.name)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(6)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Large Widget
    struct LargeWidgetView: View {
        let entry: MoodEntry
        
        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [Color.green.opacity(0.6), Color.black.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(entry.emoji)
                            .font(.system(size: 70))
                        VStack(alignment: .leading) {
                            Text(entry.mood)
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text(entry.playlistName)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    if entry.confidence > 0 {
                        Text("\(entry.confidence)% confident")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Divider().background(Color.white.opacity(0.4))
                    
                    if !entry.recentPlaylists.isEmpty {
                        Text("Recent Playlists")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        ForEach(entry.recentPlaylists.prefix(5)) { playlist in
                            HStack(spacing: 8) {
                                Text(playlist.emoji)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playlist.mood)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text(playlist.name)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding(6)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    
    // MARK: - Previews
    struct EmotiPlayWidget_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                EmotiPlayWidgetEntryView(entry: MoodEntry(
                    date: Date(),
                    mood: "Happy",
                    emoji: "😊",
                    playlistName: "Happy Vibes Playlist",
                    confidence: 87,
                    recentPlaylists: [
                        RecentPlaylist(mood: "Energetic", emoji: "⚡", name: "Workout Mix", date: Date()),
                        RecentPlaylist(mood: "Calm", emoji: "😌", name: "Chill Beats", date: Date())
                    ]
                ))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                
                EmotiPlayWidgetEntryView(entry: MoodEntry(
                    date: Date(),
                    mood: "Happy",
                    emoji: "😊",
                    playlistName: "Happy Vibes Playlist",
                    confidence: 87,
                    recentPlaylists: [
                        RecentPlaylist(mood: "Energetic", emoji: "⚡", name: "Workout Mix", date: Date()),
                        RecentPlaylist(mood: "Calm", emoji: "😌", name: "Chill Beats", date: Date())
                    ]
                ))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            }
        }
    }
}

// MARK: - Widget Configuration (moved to top-level)
@main
struct EmotiPlayWidget: Widget {
    let kind: String = "EmotiPlayWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EmotiPlayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("EmotiPlay")
        .description("Your current mood and playlists at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
