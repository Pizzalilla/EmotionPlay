# Adding Widget Extension to EmotionPlay

## Step-by-Step Guide

### 1. Add Widget Extension Target

1. In Xcode, go to **File > New > Target...**
2. Search for "Widget Extension"
3. Click **Next**
4. Configure:
   - **Product Name:** `EmotionPlayWidget`
   - **Team:** (your team)
   - **Include Configuration Intent:** ✅ Check this
   - Click **Finish**
5. When prompted "Activate EmotionPlayWidget scheme?", click **Activate**

### 2. Widget Structure

Xcode will create these files:
```
EmotionPlayWidget/
├── EmotionPlayWidget.swift          (Main widget file)
├── EmotionPlayWidget.intentdefinition
├── Assets.xcassets/
└── Info.plist
```

### 3. Create Widget Code

Replace the contents of `EmotionPlayWidget.swift`:

```swift
//
//  EmotionPlayWidget.swift
//  EmotionPlayWidget
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct MoodEntry: TimelineEntry {
    let date: Date
    let mood: String
    let emoji: String
    let playlistName: String
    let confidence: Int
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(
            date: Date(),
            mood: "Happy",
            emoji: "😊",
            playlistName: "EmotionPlay • Happy",
            confidence: 85
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> ()) {
        let entry = MoodEntry(
            date: Date(),
            mood: "Happy",
            emoji: "😊",
            playlistName: "EmotionPlay • Happy",
            confidence: 85
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Get latest mood from UserDefaults (shared with main app)
        let entry = loadLatestMood()
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadLatestMood() -> MoodEntry {
        // Use App Group to share data between app and widget
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourteam.emotionplay"),
              let moodString = sharedDefaults.string(forKey: "latestMood") else {
            return placeholder(in: Context())
        }
        
        let emoji = sharedDefaults.string(forKey: "latestEmoji") ?? "😊"
        let playlist = sharedDefaults.string(forKey: "latestPlaylist") ?? "EmotionPlay"
        let confidence = sharedDefaults.integer(forKey: "latestConfidence")
        
        return MoodEntry(
            date: Date(),
            mood: moodString,
            emoji: emoji,
            playlistName: playlist,
            confidence: confidence
        )
    }
}

// MARK: - Widget View
struct EmotionPlayWidgetEntryView : View {
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
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: MoodEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0A0A0F"), moodColor(entry.mood)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Text(entry.emoji)
                    .font(.system(size: 48))
                
                Text(entry.mood)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(entry.confidence)%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: MoodEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A0A0F"), moodColor(entry.mood).opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Mood emoji
                Text(entry.emoji)
                    .font(.system(size: 60))
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.mood)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(entry.playlistName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.system(size: 10))
                        Text("\(entry.confidence)% confident")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
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
                colors: [Color(hex: "0A0A0F"), moodColor(entry.mood).opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("EmotionPlay")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Main content
                VStack(spacing: 16) {
                    Text(entry.emoji)
                        .font(.system(size: 80))
                    
                    Text(entry.mood)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(entry.playlistName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Confidence badge
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(entry.confidence)% confident")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                Spacer()
                
                // Footer
                Text("Tap to open app")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
        }
    }
}

// MARK: - Widget Configuration
@main
struct EmotionPlayWidget: Widget {
    let kind: String = "EmotionPlayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EmotionPlayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Latest Mood")
        .description("See your most recent mood and playlist.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
struct EmotionPlayWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmotionPlayWidgetEntryView(entry: MoodEntry(
                date: Date(),
                mood: "Happy",
                emoji: "😊",
                playlistName: "EmotionPlay • Happy",
                confidence: 85
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            EmotionPlayWidgetEntryView(entry: MoodEntry(
                date: Date(),
                mood: "Calm",
                emoji: "😌",
                playlistName: "EmotionPlay • Calm Vibes",
                confidence: 92
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

// MARK: - Helpers
private func moodColor(_ mood: String) -> Color {
    switch mood.lowercased() {
    case "happy": return Color(hex: "FFA726")
    case "sad": return Color(hex: "5E92F3")
    case "calm": return Color(hex: "A78BFA")
    case "energetic": return Color(hex: "F43F5E")
    case "angry": return Color(hex: "EF4444")
    default: return Color(hex: "1DB954")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
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
```

### 4. Enable App Groups (CRITICAL for data sharing)

#### In Main App Target:
1. Select **EmotionPlay** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and add: `group.com.yourteam.emotionplay`
   (Replace `yourteam` with your actual team ID)

#### In Widget Target:
1. Select **EmotionPlayWidget** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Enable the **same App Group**: `group.com.yourteam.emotionplay`

### 5. Update HomeViewModel to Save Data for Widget

Add this to `HomeViewModel.swift` after successful playlist creation:

```swift
// Save to shared UserDefaults for widget
private func saveForWidget(mood: Mood, confidence: Double, playlistName: String) {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourteam.emotionplay") else {
        print("⚠️ Could not access shared UserDefaults")
        return
    }
    
    sharedDefaults.set(mood.rawValue.capitalized, forKey: "latestMood")
    sharedDefaults.set(moodEmoji(mood), forKey: "latestEmoji")
    sharedDefaults.set(playlistName, forKey: "latestPlaylist")
    sharedDefaults.set(Int(confidence * 100), forKey: "latestConfidence")
    sharedDefaults.synchronize()
    
    // Reload widget timeline
    WidgetCenter.shared.reloadAllTimelines()
    
    print("✅ Saved data for widget")
}

private func moodEmoji(_ mood: Mood) -> String {
    switch mood {
    case .happy: return "😊"
    case .sad: return "😢"
    case .calm: return "😌"
    case .energetic: return "⚡️"
    case .angry: return "😠"
    case .anxious: return "😰"
    case .melancholic: return "😔"
    case .focused: return "🎯"
    case .nostalgic: return "🌅"
    }
}
```

Then call it in `analyzeAndCreate()` after creating the playlist:

```swift
// 5️⃣ Save for widget
saveForWidget(mood: mood, confidence: conf, playlistName: playlistName)
```

### 6. Add WidgetKit Import

At the top of `HomeViewModel.swift`:

```swift
import WidgetKit
```

### 7. Build & Run

1. Select **EmotionPlay** scheme
2. Build and run on device/simulator
3. Long-press home screen
4. Tap **+** button (top left)
5. Search for "EmotionPlay"
6. Select widget size (Small, Medium, or Large)
7. Tap **Add Widget**

### 8. Test the Widget

1. Open EmotionPlay app
2. Upload a photo
3. Analyze mood and create playlist
4. Go to home screen
5. Widget should update with latest mood! 🎉

## Widget Features

✅ **Small Widget:** Shows emoji, mood, and confidence
✅ **Medium Widget:** Shows emoji, mood, playlist name, and confidence
✅ **Large Widget:** Full details with app branding
✅ **Auto-updates:** Refreshes every hour
✅ **Tappable:** Opens main app when tapped
✅ **Matches app design:** Dark theme with gradients

## Troubleshooting

### Widget Not Appearing
- Make sure App Groups are enabled in BOTH targets
- Use the exact same App Group ID
- Check that widget target is included in build

### Data Not Updating
- Verify App Group ID matches in both places
- Check `saveForWidget()` is being called
- Try `WidgetCenter.shared.reloadAllTimelines()`

### Build Errors
- Make sure to add WidgetKit framework
- Check minimum deployment target (iOS 14+)
- Verify all files are included in correct targets

## Alternative: Share Extension (Simpler)

If widget is too complex, you can add a Share Extension instead:

1. **File > New > Target > Share Extension**
2. Users can share playlist links directly
3. Easier to implement
4. Works with any app that has sharing

Let me know if you need help with Share Extension instead!
