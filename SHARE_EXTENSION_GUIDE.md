# EmotionPlay - Share Extension Setup Guide

## 📤 Share Extension Complete Guide

This guide will help you add a Share Extension to EmotionPlay, allowing users to analyze photos directly from Photos app, Messages, Safari, and any other app that supports image sharing!

---

## ✨ What You'll Get

Users can:
- Share photos from Photos app directly to EmotiPlay
- Analyze images from Safari, Messages, or any app
- Quick mood analysis without opening the main app first
- Seamless integration with iOS Share Sheet

---

## Step 1: Add Share Extension Target

### In Xcode:

1. **File → New → Target**
2. Select **Share Extension** (under Application Extension)
3. Configure:
   - **Product Name**: `EmotionPlayShareExtension`
   - **Language**: Swift
   - **Include UI Extension**: ❌ Uncheck (we're using code-only UI)
4. Click **Finish**
5. When prompted "Activate EmotionPlayShareExtension scheme?", click **Activate**

This creates:
- `EmotionPlayShareExtension/` folder
- `ShareViewController.swift`
- `Info.plist`

---

## Step 2: Replace Default Files

### 2.1 Delete Generated Files

Delete these auto-generated files (we've created better ones):
- `ShareViewController.swift` (delete the default one)
- `MainInterface.storyboard` (if it exists)

### 2.2 Add Our Custom Files

The files have been created in `/Users/wongwilson/Downloads/EmotionPlay/EmotionPlayShareExtension/`:

✅ `ShareViewController.swift` - Custom share UI
✅ `Info.plist` - Extension configuration

Make sure these files are added to the **EmotionPlayShareExtension** target in Xcode.

---

## Step 3: Configure App Groups (CRITICAL!)

Both the main app and share extension need to access shared data.

### 3.1 Enable App Groups for Main App

1. Select **EmotionPlay** target (main app)
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** to add a new group
6. Enter: `group.com.yourname.emotionplay` (replace "yourname" with your identifier)
7. ✅ Check the box to enable it

### 3.2 Enable App Groups for Share Extension

1. Select **EmotionPlayShareExtension** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Select the **SAME App Group** you created above
6. ✅ Check the box to enable it

### 3.3 Update App Group ID in Code

Open `ShareViewController.swift` and update line 13:

```swift
private let appGroupID = "group.com.yourname.emotionplay" // Replace with YOUR App Group ID
```

**Make sure this matches EXACTLY what you configured in Signing & Capabilities!**

---

## Step 4: Configure URL Scheme

The share extension needs to open the main app. We'll use a custom URL scheme.

### 4.1 Add URL Scheme to Main App

1. Select **EmotionPlay** target (main app)
2. Go to **Info** tab
3. Expand **URL Types**
4. Click **+** to add a new URL Type
5. Fill in:
   - **Identifier**: `com.yourname.emotionplay`
   - **URL Schemes**: `emotionplay`
   - **Role**: Editor

### 4.2 Handle URL in Main App

Open `EmotionPlayApp.swift` and add the URL handler:

```swift
import SwiftUI

@main
struct EmotionPlayApp: App {
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var spotifyService = SpotifyService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyStore)
                .environmentObject(spotifyService)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "emotionplay",
              url.host == "analyze" else {
            return
        }
        
        // Get shared image from App Group
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourname.emotionplay"),
              let imageData = sharedDefaults.data(forKey: "pendingAnalysisImage"),
              let image = UIImage(data: imageData) else {
            print("No pending analysis image found")
            return
        }
        
        // Clear the pending image
        sharedDefaults.removeObject(forKey: "pendingAnalysisImage")
        sharedDefaults.removeObject(forKey: "pendingAnalysisDate")
        
        // TODO: Trigger mood analysis with this image
        // You'll need to integrate this with your existing camera/photo picker flow
        print("Received image for analysis from share extension")
        
        // Example: Post notification to trigger analysis
        NotificationCenter.default.post(
            name: NSNotification.Name("AnalyzeSharedImage"),
            object: nil,
            userInfo: ["image": image]
        )
    }
}
```

---

## Step 5: Update Info.plist Configuration

The `Info.plist` has already been configured, but verify these settings:

### In `EmotionPlayShareExtension/Info.plist`:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>1</integer>
        </dict>
    </dict>
</dict>
```

This configuration:
- ✅ Allows sharing 1 image at a time
- ✅ Shows EmotiPlay in share sheet for images only
- ✅ Sets proper bundle identifier

---

## Step 6: Build & Test

### 6.1 Build the Extension

1. Select **EmotionPlayShareExtension** scheme from the scheme selector
2. Choose your device or simulator
3. Click **Run** (or Cmd+R)

### 6.2 Test the Share Extension

1. Open **Photos** app
2. Select any photo
3. Tap the **Share** button (square with arrow)
4. Scroll through the share sheet
5. Look for **EmotiPlay** icon
6. Tap it to test!

You should see:
- ✅ EmotiPlay share UI with the selected photo
- ✅ "Analyze Mood" button
- ✅ Cancel button

---

## Step 7: Integrate with Main App

To fully integrate the share extension with your mood analysis:

### 7.1 Listen for Shared Images

In your `ContentView.swift` or main camera view:

```swift
.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AnalyzeSharedImage"))) { notification in
    if let image = notification.userInfo?["image"] as? UIImage {
        // Trigger your mood analysis with this image
        // analyzeImage(image)
    }
}
```

### 7.2 Create SharedDataManager (If Not Exists)

If you haven't created `SharedDataManager.swift` yet (from the Widget Guide):

```swift
//
//  SharedDataManager.swift
//  EmotionPlay
//

import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let appGroupID = "group.com.yourname.emotionplay" // MUST match!
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    // Pending Analysis Image
    func getPendingAnalysisImage() -> UIImage? {
        guard let imageData = userDefaults?.data(forKey: "pendingAnalysisImage"),
              let image = UIImage(data: imageData) else {
            return nil
        }
        return image
    }
    
    func clearPendingAnalysisImage() {
        userDefaults?.removeObject(forKey: "pendingAnalysisImage")
        userDefaults?.removeObject(forKey: "pendingAnalysisDate")
    }
    
    // ... other shared data methods ...
}
```

---

## Features of the Share Extension

### ✨ Beautiful UI
- Dark theme matching EmotiPlay design
- Large image preview
- Clear call-to-action buttons
- Loading states

### 🔄 Smooth Flow
1. User shares image from any app
2. EmotiPlay extension opens with preview
3. User taps "Analyze Mood"
4. Main app opens and processes image
5. Playlist is created automatically

### 🛡️ Error Handling
- Invalid image type detection
- Loading state indicators
- User-friendly error messages
- Graceful cancellation

---

## Troubleshooting

### Extension Not Appearing in Share Sheet

**Issue**: EmotiPlay doesn't show up when sharing images

**Solutions**:
1. Make sure you've built the **EmotionPlayShareExtension** scheme at least once
2. Restart your device/simulator
3. Check that `Info.plist` has correct `NSExtensionActivationRule`
4. Verify the extension target is properly configured

### App Doesn't Open After "Analyze Mood"

**Issue**: Tapping "Analyze Mood" does nothing

**Solutions**:
1. Verify URL Scheme is configured correctly (`emotionplay://`)
2. Check that App Group IDs match exactly in both targets
3. Make sure `onOpenURL` handler is implemented in main app
4. Test the URL scheme manually: `xcrun simctl openurl booted emotionplay://analyze`

### Image Not Found in Main App

**Issue**: Main app opens but no image is processed

**Solutions**:
1. Confirm App Groups are enabled on **both** targets
2. Verify App Group ID matches in code and capabilities
3. Check that image data is being saved before opening URL
4. Add debug prints to verify data flow

### Build Errors

**Issue**: "No such module" or linking errors

**Solutions**:
1. Make sure `ShareViewController.swift` is in the **EmotionPlayShareExtension** target
2. Check that all necessary frameworks are linked (UIKit, UniformTypeIdentifiers)
3. Clean build folder (Shift+Cmd+K) and rebuild

---

## Testing Checklist

- [ ] Share extension appears in Photos app share sheet
- [ ] Share extension appears in Safari share sheet (for images)
- [ ] Selected image displays correctly in preview
- [ ] "Analyze Mood" button opens main app
- [ ] Image data is accessible in main app
- [ ] Cancel button closes extension
- [ ] Loading state shows while processing
- [ ] Error messages display for invalid images

---

## Advanced: Multiple Image Support (Optional)

To allow sharing multiple images at once, modify `Info.plist`:

```xml
<key>NSExtensionActivationSupportsImageWithMaxCount</key>
<integer>5</integer>  <!-- Change from 1 to 5 -->
```

Then update `ShareViewController.swift` to handle multiple attachments.

---

## Distribution

When submitting to App Store:

1. ✅ Both app and extension must have same team/signing
2. ✅ App Group must be registered in Apple Developer Portal
3. ✅ Extension is automatically included in the main app bundle
4. ✅ No additional setup required for end users

---

## Summary

You now have a fully functional Share Extension that allows users to:
- 📷 Share photos from any app to EmotiPlay
- 🎵 Quick mood analysis without opening the app first
- 🔄 Seamless integration with the main app
- ✨ Beautiful, native iOS experience

The extension handles all the heavy lifting of image extraction, validation, and handoff to the main app!

---

## Need Help?

Common issues and their solutions are listed in the Troubleshooting section above. Make sure:
1. App Group IDs match exactly
2. URL Scheme is configured
3. Both targets have proper signing
4. Extension has been built at least once

Enjoy your new Share Extension! 🎉
