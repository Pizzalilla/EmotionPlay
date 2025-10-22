//
//  EmotiPlayWidget.swift
//  EmotiPlayWidget
//
//  Widget Extension for EmotiPlay - CalAI inspired design
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct EmotiPlayProvider: TimelineProvider {
    func placeholder(in context: Context) -> EmotiPlayEntry {
        EmotiPlayEntry(
            date: Date(),
            mood: .happy,
            playlistName: "Happy Vibes",
            confidence: 0.85,
            moodCount: 5
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (EmotiPlayEntry) -> Void) {
        let entry = EmotiPlayEntry(
            date: Date(),
            mood: .happy,
            playlistName: "Happy Vibes",
            confidence: 0.85,
            moodCount: 5
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<EmotiPlayEntry>) -> Void) {
        // Read from App Group shared data
        let entry = loadLatestMood() ?? EmotiPlayEntry(
            date: Date(),
            mood: nil,
            playlistName: "No recent mood",
            confidence: 0.0,
            moodCount: 0
        )
        
        // Update every 15 minutes
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }
    
    private func loadLatestMood() -> EmotiPlayEntry? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.emotionplay.shared"),
              let data = sharedDefaults.data(forKey: "latestMood") else {
            return nil
        }
        
        return try? JSONDecoder().decode(EmotiPlayEntry.self, from: data)
    }
}

// MARK: - Timeline Entry
struct EmotiPlayEntry: TimelineEntry, Codable {
    let date: Date
    let mood: Mood?
    let playlistName: String
    let confidence: Double
    let moodCount: Int
}

// MARK: - Widget Configuration
struct EmotiPlayWidget: Widget {
    let kind: String = "EmotiPlayWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EmotiPlayProvider()) { entry in
            EmotiPlayWidgetView(entry: entry)
        }
        .configurationDisplayName("EmotiPlay")
        .description("View your current mood and recent playlist")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View
struct EmotiPlayWidgetView: View {
    let entry: EmotiPlayEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Circular Mood Display)
struct SmallWidgetView: View {
    let entry: EmotiPlayEntry
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0A0A0F"), Color(hex: "1C1C23")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if let mood = entry.mood {
                VStack(spacing: 12) {
                    // Mood Circle
                    ZStack {
                        Circle()
                            .fill(moodGradient(mood))
                            .frame(width: 80, height: 80)
                            .shadow(color: moodColor(mood).opacity(0.6), radius: 15, x: 0, y: 5)
                        
                        Text(moodEmoji(mood))
                            .font(.system(size: 40))
                    }
                    
                    // Mood Label
                    VStack(spacing: 4) {
                        Text(mood.rawValue.capitalized)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("\(Int(entry.confidence * 100))%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "2A2A35"))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text("No mood yet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .widgetURL(URL(string: "emotionplay://home"))
    }
    
    private func moodEmoji(_ mood: Mood) -> String {
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .melancholic: return "🌧️"
        case .focused: return "🎯"
        case .nostalgic: return "💭"
        }
    }
    
    private func moodGradient(_ mood: Mood) -> LinearGradient {
        switch mood {
        case .happy:
            return LinearGradient(
                colors: [Color(hex: "FFD93D"), Color(hex: "FFA726")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sad:
            return LinearGradient(
                colors: [Color(hex: "5E92F3"), Color(hex: "3B82F6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calm:
            return LinearGradient(
                colors: [Color(hex: "A78BFA"), Color(hex: "8B5CF6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .energetic:
            return LinearGradient(
                colors: [Color(hex: "F43F5E"), Color(hex: "EC4899")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(hex: "6B7280"), Color(hex: "4B5563")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func moodColor(_ mood: Mood) -> Color {
        switch mood {
        case .happy: return Color(hex: "FFA726")
        case .sad: return Color(hex: "3B82F6")
        case .calm: return Color(hex: "8B5CF6")
        case .energetic: return Color(hex: "EC4899")
        default: return Color(hex: "6B7280")
        }
    }
}

// MARK: - Medium Widget (Detailed View)
struct MediumWidgetView: View {
    let entry: EmotiPlayEntry
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0A0A0F"), Color(hex: "1C1C23")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Left: Mood Circle
                if let mood = entry.mood {
                    ZStack {
                        Circle()
                            .fill(moodGradient(mood))
                            .frame(width: 90, height: 90)
                            .shadow(color: moodColor(mood).opacity(0.6), radius: 15, x: 0, y: 5)
                        
                        Text(moodEmoji(mood))
                            .font(.system(size: 44))
                    }
                    .padding(.leading, 12)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "2A2A35"))
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.leading, 12)
                }
                
                // Right: Info
                VStack(alignment: .leading, spacing: 8) {
                    // App name
                    HStack(spacing: 6) {
                        Image(systemName: "music.note.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "1DB954"))
                        Text("EmotiPlay")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let mood = entry.mood {
                        // Current mood
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mood.rawValue.capitalized)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("\(Int(entry.confidence * 100))% confidence")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        // Playlist info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.playlistName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "1DB954"))
                                .lineLimit(1)
                            
                            Text("\(entry.moodCount) moods this week")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else {
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No mood detected")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Tap to capture your mood")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                }
                .padding(.trailing, 16)
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .widgetURL(URL(string: "emotionplay://home"))
    }
    
    private func moodEmoji(_ mood: Mood) -> String {
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .melancholic: return "🌧️"
        case .focused: return "🎯"
        case .nostalgic: return "💭"
        }
    }
    
    private func moodGradient(_ mood: Mood) -> LinearGradient {
        switch mood {
        case .happy:
            return LinearGradient(
                colors: [Color(hex: "FFD93D"), Color(hex: "FFA726")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sad:
            return LinearGradient(
                colors: [Color(hex: "5E92F3"), Color(hex: "3B82F6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .calm:
            return LinearGradient(
                colors: [Color(hex: "A78BFA"), Color(hex: "8B5CF6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .energetic:
            return LinearGradient(
                colors: [Color(hex: "F43F5E"), Color(hex: "EC4899")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(hex: "6B7280"), Color(hex: "4B5563")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func moodColor(_ mood: Mood) -> Color {
        switch mood {
        case .happy: return Color(hex: "FFA726")
        case .sad: return Color(hex: "3B82F6")
        case .calm: return Color(hex: "8B5CF6")
        case .energetic: return Color(hex: "EC4899")
        default: return Color(hex: "6B7280")
        }
    }
}

// MARK: - Preview
struct EmotiPlayWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmotiPlayWidgetView(entry: EmotiPlayEntry(
                date: Date(),
                mood: .happy,
                playlistName: "Happy Vibes Mix",
                confidence: 0.85,
                moodCount: 7
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small Widget")
            
            EmotiPlayWidgetView(entry: EmotiPlayEntry(
                date: Date(),
                mood: .calm,
                playlistName: "Peaceful Moments",
                confidence: 0.92,
                moodCount: 12
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium Widget")
            
            EmotiPlayWidgetView(entry: EmotiPlayEntry(
                date: Date(),
                mood: nil,
                playlistName: "No recent mood",
                confidence: 0.0,
                moodCount: 0
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Empty State")
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Mood enum copy for widget
enum Mood: String, Codable {
    case happy, calm, sad, energetic, angry, anxious, melancholic, focused, nostalgic
}
