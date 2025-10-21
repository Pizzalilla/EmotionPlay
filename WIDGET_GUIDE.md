# EmotionPlay - Adding iOS Widgets

## 📱 Widget Extension Setup Guide

This guide will help you add Home Screen and Lock Screen widgets to EmotionPlay so users can see their mood history and quick stats right from their home screen!

---

## Step 1: Add Widget Extension Target

### In Xcode:

1. **File → New → Target**
2. Select **Widget Extension**
3. Name it: `EmotionPlayWidget`
4. ✅ Check "Include Configuration Intent" (for customizable widgets)
5. Click **Finish**
6. When prompted "Activate EmotionPlayWidget scheme?", click **Activate**

This creates:
- `EmotionPlayWidget/` folder
- `EmotionPlayWidget.swift`
- `EmotionPlayWidgetBundle.swift`
- Widget assets folder

---

## Step 2: Share Data Between App & Widget

Widgets need access to your app's data. We'll use **App Groups**.

### 2.1 Enable App Groups

1. Select your **EmotionPlay target** (main app)
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Click the **+** button
6. Enter: `group.com.yourname.emotionplay` (replace yourname)
7. Check the box to enable it

8. Now select **EmotionPlayWidget target**
9. Repeat steps 2-7 with the **same App Group ID**

### 2.2 Create Shared Data Manager

Create a new file: `EmotionPlay/Utilities/SharedDataManager.swift`

```swift
//
//  SharedDataManager.swift
//  EmotionPlay
//

import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()
    
    // MUST match the App Group you created!
    private let appGroupID = "group.com.yourname.emotionplay"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // MARK: - Save Methods
    
    func saveLatestMood(_ mood: Mood, confidence: Double) {
        userDefaults?.set(mood.rawValue, forKey: "latestMood")
        userDefaults?.set(confidence, forKey: "latestConfidence")
        userDefaults?.set(Date(), forKey: "latestMoodDate")
    }
    
    func saveMoodCount(_ count: Int) {
        userDefaults?.set(count, forKey: "totalMoodCount")
    }
    
    func saveWeeklyStreak(_ streak: Int) {
        userDefaults?.set(streak, forKey: "weeklyStreak")
    }
    
    // MARK: - Retrieve Methods
    
    func getLatestMood() -> (mood: Mood, confidence: Double, date: Date)? {
        guard let moodRaw = userDefaults?.string(forKey: "latestMood"),
              let mood = Mood(rawValue: moodRaw),
              let date = userDefaults?.object(forKey: "latestMoodDate") as? Date else {
            return nil
        }
        let confidence = userDefaults?.double(forKey: "latestConfidence") ?? 0.0
        return (mood, confidence, date)
    }
    
    func getTotalMoodCount() -> Int {
        userDefaults?.integer(forKey: "totalMoodCount") ?? 0
    }
    
    func getWeeklyStreak() -> Int {
        userDefaults?.integer(forKey: "weeklyStreak") ?? 0
    }
}
```

### 2.3 Update HistoryStore to Share Data

Edit `EmotionPlay/Store/HistoryStore.swift`:

```swift
final class HistoryStore: ObservableObject {
  @Published var items: [HistoryItem] = []

  func add(_ item: HistoryItem) { 
    items.insert(item, at: 0)
    
    // Share data with widget
    SharedDataManager.shared.saveLatestMood(item.mood, confidence: item.confidence ?? 0.0)
    SharedDataManager.shared.saveMoodCount(items.count)
    updateStreak()
  }
  
  private func updateStreak() {
    let calendar = Calendar.current
    let today = Date()
    var streak = 0
    
    for item in items.sorted(by: { $0.date > $1.date }) {
        let daysAgo = calendar.dateComponents([.day], from: item.date, to: today).day ?? 0
        if daysAgo == streak {
            streak += 1
        } else {
            break
        }
    }
    
    SharedDataManager.shared.saveWeeklyStreak(streak)
  }
    
  func rename(id: HistoryItem.ID, to newTitle: String) {
    guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
    items[idx].playlistName = newTitle
  }
  
  func delete(at offsets: IndexSet) { 
    items.remove(atOffsets: offsets)
    SharedDataManager.shared.saveMoodCount(items.count)
    updateStreak()
  }
  
  func clearAll() { 
    items.removeAll()
    SharedDataManager.shared.saveMoodCount(0)
    SharedDataManager.shared.saveWeeklyStreak(0)
  }
}
```

---

## Step 3: Create Widget UI

### 3.1 Widget Entry Model

Replace `EmotionPlayWidget/EmotionPlayWidget.swift` with:

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
    let mood: Mood?
    let confidence: Double
    let totalCount: Int
    let streak: Int
    let moodDate: Date?
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(date: Date(), mood: .happy, confidence: 0.85, totalCount: 12, streak: 3, moodDate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodEntry>) -> Void) {
        let entry = createEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createEntry() -> MoodEntry {
        let moodData = SharedDataManager.shared.getLatestMood()
        let count = SharedDataManager.shared.getTotalMoodCount()
        let streak = SharedDataManager.shared.getWeeklyStreak()
        
        return MoodEntry(
            date: Date(),
            mood: moodData?.mood,
            confidence: moodData?.confidence ?? 0.0,
            totalCount: count,
            streak: streak,
            moodDate: moodData?.date
        )
    }
}

// MARK: - Widget View
struct EmotionPlayWidgetEntryView: View {
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
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Home Screen)
struct SmallWidgetView: View {
    let entry: MoodEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1C1C23"), Color(hex: "0A0A0F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Text(moodEmoji(entry.mood))
                    .font(.system(size: 48))
                
                if let mood = entry.mood {
                    Text(mood.rawValue.capitalized)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(Int(entry.confidence * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                } else {
                    Text("No Mood Yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if entry.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                        Text("\(entry.streak)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
    }
    
    private func moodEmoji(_ mood: Mood?) -> String {
        guard let mood = mood else { return "😐" }
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .melancholic: return "😔"
        case .focused: return "🎯"
        case .nostalgic: return "🌅"
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: MoodEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1C1C23"), Color(hex: "0A0A0F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Left: Mood
                VStack(spacing: 4) {
                    Text(moodEmoji(entry.mood))
                        .font(.system(size: 56))
                    
                    if let mood = entry.mood {
                        Text(mood.rawValue.capitalized)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("\(Int(entry.confidence * 100))% confident")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Right: Stats
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(icon: "music.note.list", value: "\(entry.totalCount)", label: "Playlists")
                    StatRow(icon: "flame.fill", value: "\(entry.streak)", label: "Day Streak")
                    
                    if let date = entry.moodDate {
                        Text(timeAgo(from: date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
    
    private func moodEmoji(_ mood: Mood?) -> String {
        guard let mood = mood else { return "😐" }
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .melancholic: return "😔"
        case .focused: return "🎯"
        case .nostalgic: return "🌅"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: MoodEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1C1C23"), Color(hex: "0A0A0F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("EmotiPlay")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    if let date = entry.moodDate {
                        Text(timeAgo(from: date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Main Mood Display
                VStack(spacing: 12) {
                    Text(moodEmoji(entry.mood))
                        .font(.system(size: 72))
                    
                    if let mood = entry.mood {
                        Text(mood.rawValue.capitalized)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        ProgressView(value: entry.confidence)
                            .tint(Color(hex: "1DB954"))
                            .frame(width: 150)
                        
                        Text("\(Int(entry.confidence * 100))% Confidence")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("No mood detected yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Open the app to analyze a photo!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Stats Grid
                HStack(spacing: 20) {
                    StatCard(icon: "music.note.list", value: "\(entry.totalCount)", label: "Total")
                    StatCard(icon: "flame.fill", value: "\(entry.streak)", label: "Streak")
                    StatCard(icon: "star.fill", value: "\(Int(entry.confidence * 100))%", label: "Score")
                }
            }
            .padding()
        }
    }
    
    private func moodEmoji(_ mood: Mood?) -> String {
        guard let mood = mood else { return "😐" }
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .melancholic: return "😔"
        case .focused: return "🎯"
        case .nostalgic: return "🌅"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }
}

// MARK: - Lock Screen Widgets

struct CircularWidgetView: View {
    let entry: MoodEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text(moodEmoji(entry.mood))
                .font(.system(size: 24))
        }
    }
    
    private func moodEmoji(_ mood: Mood?) -> String {
        guard let mood = mood else { return "😐" }
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .melancholic: return "😔"
        case .focused: return "🎯"
        case .nostalgic: return "🌅"
        }
    }
}

struct RectangularWidgetView: View {
    let entry: MoodEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Text(moodEmoji(entry.mood))
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 2) {
                if let mood = entry.mood {
                    Text(mood.rawValue.capitalized)
                        .font(.caption.bold())
                    Text("\(Int(entry.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                } else {
                    Text("No Mood")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            if entry.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                    Text("\(entry.streak)")
                        .font(.caption2.bold())
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func moodEmoji(_ mood: Mood?) -> String {
        guard let mood = mood else { return "😐" }
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .melancholic: return "😔"
        case .focused: return "🎯"
        case .nostalgic: return "🌅"
        }
    }
}

// MARK: - Helper Views

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "1DB954"))
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "1DB954"))
                .font(.system(size: 20))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(hex: "2A2A35"))
        .cornerRadius(12)
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
        .configurationDisplayName("Mood Widget")
        .description("See your latest mood and stats at a glance")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
```

### 3.2 Copy Shared Files

You need to make `Mood.swift` and `SharedDataManager.swift` available to the widget:

1. Select `Mood.swift` in the Project Navigator
2. In the File Inspector (right panel), under **Target Membership**
3. Check ✅ **EmotionPlayWidget**

4. Do the same for `SharedDataManager.swift`

---

## Step 4: Test Your Widget

1. **Build & Run** the main app
2. Add a mood (analyze a photo)
3. **Long press** on home screen
4. Tap **+** button
5. Search for "EmotionPlay"
6. Add your widget!

---

## Widget Features:

- **Small Widget**: Latest mood emoji + confidence + streak
- **Medium Widget**: Mood + full stats
- **Large Widget**: Detailed view with progress bar
- **Lock Screen Widgets**: Circular & rectangular options

The widgets auto-update every 15 minutes!

---

## Troubleshooting:

**Widget shows "No Mood"?**
- Make sure you've analyzed at least one photo in the main app
- Check that App Group IDs match exactly

**Widget not updating?**
- Widgets update every 15 minutes by default
- Force reload: Remove and re-add the widget

**Build errors?**
- Make sure `Mood.swift` is included in widget target
- Verify App Group is enabled on both targets
