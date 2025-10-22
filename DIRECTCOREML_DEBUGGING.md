# DirectCoreMLInferencer Debugging Guide

## Issue Summary
The Core ML model loads successfully (showing "✅ Model loaded: 360x360"), but predictions are not appearing in the console when running on a physical iPhone.

## Root Cause Analysis

### Why You're Not Seeing Predictions

1. **Print Statements Don't Always Show on Device**
   - Standard `print()` statements may not appear in Xcode console when running on a physical device
   - This happens especially if the device gets disconnected or if execution happens in the background
   - The app may be running fine, but you can't see the output

2. **iOS 14+ Changed Logging Behavior**
   - Apple's `os_log` / `Logger` API is now the recommended way to log on devices
   - Traditional `print()` statements are often suppressed on physical devices
   - Console app on Mac can see these logs, but Xcode console may not

3. **Possible Silent Failures**
   - The model might be throwing errors that aren't being caught
   - The pixel buffer conversion might be failing silently
   - Threading issues could cause crashes that don't show in console

## Fixes Applied

### 1. Added OSLog Logger ✅
**Changed from:**
```swift
print("📊 Predictions:")
for (label, prob) in probabilities.sorted(by: { $0.value > $1.value }) {
    print("  \(label): \(Int(prob * 100))%")
}
```

**Changed to:**
```swift
import OSLog
private let logger = Logger(subsystem: "com.emotionplay.inference", category: "CoreML")

logger.info("📊 Predictions:")
for (label, prob) in sortedProbs {
    logger.info("  \(label): \(Int(prob * 100))%")
}
// Keep print statements as backup
print("📊 DirectCoreML Predictions:")
for (label, prob) in sortedProbs {
    print("  \(label): \(Int(prob * 100))%")
}
```

### 2. Added Comprehensive Step-by-Step Logging ✅
Now logs every step of the inference process:
- ✅ Image data received
- ✅ UIImage created
- ✅ CGImage obtained
- ✅ Pixel buffer creation started
- ✅ Pixel buffer created successfully
- 🔮 Running model prediction
- ✅ Prediction completed
- 📊 All probabilities with percentages
- ✅ Final mood mapping result

### 3. Enhanced Error Handling ✅
Added detailed error logging at every failure point:
- ❌ Failed to create UIImage
- ❌ Failed to get CGImage
- ❌ Failed to create pixel buffer
- ❌ CVPixelBufferCreate failed with status code
- ❌ Failed to create CGContext
- ❌ Prediction error with full description

### 4. Added Weak Self Protection ✅
```swift
inferenceQueue.async { [weak self] in
    guard let self = self else {
        logger.error("❌ Self was deallocated during inference")
        continuation.resume(throwing: CoreMLError.modelLoadFailed)
        return
    }
    // ... rest of code
}
```

### 5. Enhanced HomeViewModel Logging ✅
Added comprehensive logging throughout the entire workflow:
- 🚀 Process start
- ✅ Pre-flight checks (image data, auth)
- 🔮 Mood inference start/complete
- 🎵 Genres being used
- 🔍 Track recommendation fetching
- 📝 Playlist creation
- ➕ Track addition
- 🎉 Success/failure states

### 6. Improved Label Mapping ✅
Extended emotion label mapping to handle common classifier outputs:
```swift
case "happy": return .happy
case "sad": return .sad
case "angry": return .angry
case "surprised": return .energetic
case "fear", "fearful": return .anxious
case "disgust": return .angry
case "neutral": return .calm
default: return .calm  // with warning log
```

## How to View Logs on Physical Device

### Method 1: Xcode Console (Basic)
1. Keep iPhone connected via cable
2. Run app from Xcode
3. Look in Xcode Console (⇧⌘C)
4. Filter by "emotionplay" to see only relevant logs

### Method 2: Console App (Advanced - RECOMMENDED)
1. Open **Console.app** on your Mac (in /Applications/Utilities/)
2. Select your iPhone from the left sidebar
3. In the search field, enter: `subsystem:com.emotionplay`
4. Click "Start" to begin streaming logs
5. Run your app and take/upload a photo
6. Watch the logs appear in real-time

**Console.app Advantages:**
- Shows ALL logs, including those suppressed in Xcode
- Persists after device disconnection
- Better filtering and search
- Can save logs to file for analysis

### Method 3: Terminal (Power Users)
```bash
# Install libimobiledevice (if not installed)
brew install libimobiledevice

# Stream device logs
idevicesyslog | grep "emotionplay"
```

## Testing Checklist

### Basic Smoke Test
- [ ] App launches without crashes
- [ ] "✅ Model loaded: 360x360" appears in logs
- [ ] Can take/upload a photo
- [ ] Photo appears in the UI
- [ ] "Analyze Photo & Create Playlist" button is enabled
- [ ] Button shows loading state when tapped

### Detailed Inference Test
With Console.app open and filtered to `subsystem:com.emotionplay`:

1. **Upload a Photo**
   - [ ] See: "🚀 Starting analyzeAndCreate..."
   - [ ] See: "✅ Image data available: [size] bytes"
   - [ ] See: "✅ Spotify authorized"

2. **Mood Inference Phase**
   - [ ] See: "🔮 Starting mood inference..."
   - [ ] See: "🖼️ Starting inference with image data"
   - [ ] See: "✅ UIImage created: [dimensions]"
   - [ ] See: "✅ CGImage obtained"
   - [ ] See: "🎨 Creating pixel buffer: 360x360"
   - [ ] See: "✅ Pixel buffer created successfully"
   - [ ] See: "🔮 Running model prediction..."
   - [ ] See: "✅ Prediction completed"
   - [ ] See: "📊 Predictions:" followed by probability list
   - [ ] See: "✅ Final: [label] → [mood] ([confidence]%)"
   - [ ] See: "🎯 HomeViewModel: Detected [mood]"

3. **Playlist Creation Phase**
   - [ ] See: "🎵 Using genres: [genre list]"
   - [ ] See: "🔍 Fetching track recommendations..."
   - [ ] See: "✅ Got [N] track URIs"
   - [ ] See: "📝 Creating playlist: [name]"
   - [ ] See: "✅ Playlist created with ID: [id]"
   - [ ] See: "➕ Adding [N] tracks to playlist..."
   - [ ] See: "✅ Tracks added successfully"
   - [ ] See: "🎉 Success! Updating UI..."

4. **UI Update**
   - [ ] Mood stats section appears
   - [ ] Shows detected mood emoji
   - [ ] Shows confidence percentage
   - [ ] "Playlist Created" card appears
   - [ ] Can click "Open in Spotify"

### Error Scenarios to Test

1. **No Internet Connection**
   - Should see: "❌ Prediction error" or network timeout
   - Should show error message in UI

2. **Spotify Not Connected**
   - Should see: "⚠️ Not authorized with Spotify"
   - Should show: "Please connect Spotify in the Profile tab."

3. **No Image Selected**
   - Should see: " No image data selected"
   - Should show: "Please select a photo first."

4. **Invalid Image**
   - Should see: "❌ Failed to create UIImage from data"
   - Or: "❌ Failed to get CGImage from UIImage"

## Common Issues and Solutions

### Issue 1: Model Loads But No Predictions
**Symptoms:**
- See "✅ Model loaded: 360x360"
- Don't see any prediction logs
- App doesn't crash

**Solutions:**
1. Check Console.app instead of Xcode console
2. Verify inference is actually being called:
   - Add breakpoint in `analyzeAndCreate()` method
   - Step through and confirm it reaches `inferencer.infer()`
3. Check if task is being cancelled (SwiftUI view dismissal)

### Issue 2: Pixel Buffer Creation Fails
**Symptoms:**
- See "🎨 Creating pixel buffer: 360x360"
- Don't see "✅ Pixel buffer created successfully"
- Error about image conversion

**Solutions:**
1. Check image format - ensure it's a standard image format
2. Try with a simple test image (solid color)
3. Check available memory on device

### Issue 3: Wrong Mood Detection
**Symptoms:**
- Prediction completes successfully
- But mood doesn't match image emotion

**Solutions:**
1. Check the raw predictions in logs
2. Model may need retraining with better data
3. Verify label mapping in `mapClassificationToMood()`
4. Consider using a dedicated emotion recognition model

### Issue 4: Logs Not Appearing
**Symptoms:**
- App runs fine
- No logs appear anywhere

**Solutions:**
1. Use Console.app instead of Xcode
2. Check log level settings in Console.app
3. Ensure device is in development mode
4. Try unplugging and replugging device

## Performance Monitoring

### Expected Timings
- Model initialization: < 500ms
- Pixel buffer creation: < 100ms
- Inference: 50-300ms (varies by device)
- Total end-to-end: 2-5 seconds (including Spotify API calls)

### If Inference is Slow
1. Check if using Neural Engine (computeUnits: .all)
2. Verify model is optimized for mobile
3. Consider quantizing model if accuracy allows
4. Profile with Instruments

## Model Information

**Current Model:** EmotiPlayFinal.mlmodel
- **Input:** 360x360 RGB image (kCVPixelFormatType_32BGRA)
- **Output:** String label + probability dictionary
- **Expected Labels:** happy, sad, angry, surprised, fear, disgust, neutral

**Label Mapping:**
```
happy → .happy
sad → .sad
angry → .angry
surprised → .energetic
fear/fearful → .anxious
disgust → .angry
neutral → .calm
```

## Files Modified

1. **DirectCoreMLInfencer.swift**
   - Added OSLog Logger
   - Added comprehensive logging at every step
   - Enhanced error messages
   - Added weak self protection
   - Enhanced label mapping with more cases
   - Dual logging (both OSLog and print)

2. **HomeViewModel.swift**
   - Added OSLog Logger
   - Added step-by-step workflow logging
   - Enhanced error reporting
   - Added data size logging
   - Better visibility into entire flow

## Verification Steps

### Step 1: Verify Model is Working
Test with a simple emotion:

1. Take/upload a photo with clear happy emotion
2. Check Console.app for logs
3. Verify you see all these logs in order:
   ```
   🔍 Loading Core ML model...
   ✅ Model loaded: 360x360
   🚀 Starting analyzeAndCreate...
   ✅ Image data available: [size] bytes
   ✅ Spotify authorized
   🔮 Starting mood inference...
   🖼️ Starting inference with image data of size: [size] bytes
   ✅ UIImage created: [width]x[height]
   ✅ CGImage obtained
   🎨 Creating pixel buffer: 360x360
   📐 Image transform - scale: [value], offset: ([x], [y])
   ✅ Pixel buffer created successfully
   🔮 Running model prediction...
   ✅ Prediction completed
   📊 Predictions:
     [label1]: [prob1]%
     [label2]: [prob2]%
     ...
   ✅ Final: [label] → [mood] ([confidence]%)
   🎯 HomeViewModel: Detected [mood] ([confidence]%)
   ```

4. If you see ALL of these, the model is working!

### Step 2: Verify Full Workflow
1. Ensure Spotify is connected
2. Select at least one preferred genre
3. Take/upload a photo
4. Click "Analyze Photo & Create Playlist"
5. Wait 5-10 seconds
6. Check for success or error message

### Step 3: Check Spotify Integration
If mood detection works but playlist creation fails:
1. Check: "✅ Got [N] track URIs"
   - If N = 0, no tracks were found (genre issue)
   - If N > 0, tracks found successfully
2. Check: "📝 Creating playlist: [name]"
3. Check for errors like "401 Unauthorized" or "403 Forbidden"

## Debugging Commands

### View All Logs in Real-Time
```bash
# In Console.app, use this filter:
subsystem:com.emotionplay

# Or search for specific components:
subsystem:com.emotionplay.inference
subsystem:com.emotionplay.viewmodel
```

### Save Logs to File
1. In Console.app, after reproducing the issue:
2. File → Save Selection... (⌘S)
3. Save as "emotionplay-debug-[date].txt"
4. Can share for debugging

### Filter by Log Level
In Console.app sidebar:
- ✅ Info (green) - Normal operation
- ⚠️ Warning (yellow) - Non-critical issues
- ❌ Error (red) - Failures

## Expected Behavior vs Actual

### Expected Flow:
```
User uploads photo
  ↓
Image converted to 360x360 pixel buffer
  ↓
Core ML model processes image
  ↓
Returns emotion label + probabilities
  ↓
Mapped to Mood enum
  ↓
Spotify API fetches tracks for mood
  ↓
Playlist created and tracks added
  ↓
UI shows success with "Open in Spotify" link
```

### Common Failure Points:
1. **Image conversion** - Wrong format or corrupted
2. **Model inference** - OOM or model error
3. **Label mapping** - Unexpected label from model
4. **Spotify API** - Auth expired or network error
5. **Track fetching** - No matching genres

## Advanced Debugging

### Enable Verbose Core ML Logging
Add to your scheme (Edit Scheme → Run → Arguments):
```
-com.apple.CoreML.logging 1
```

### Check Memory Usage
If app crashes during inference:
1. Open Xcode Memory Debugger (Debug → Memory Graph)
2. Look for memory spikes during inference
3. May need to reduce image quality or model size

### Profile with Instruments
1. Product → Profile (⌘I)
2. Select "Time Profiler"
3. Record while analyzing photo
4. Look for bottlenecks in inference

## Known Limitations

1. **Model Accuracy**: Current model may not be emotion-specific
   - Consider using dedicated emotion recognition model
   - FER2013 or AffectNet trained models

2. **Single Face Only**: Model doesn't specify multi-face handling
   - May give unpredictable results with multiple faces
   - Consider adding face detection preprocessing

3. **Lighting Sensitivity**: Image quality affects results
   - Poor lighting may reduce accuracy
   - Consider image preprocessing/normalization

4. **Device Performance**: Varies by iPhone model
   - Newer devices: 50-100ms inference
   - Older devices: 200-300ms inference
   - Consider showing loading indicator

## Troubleshooting Quick Reference

| Symptom | Possible Cause | Solution |
|---------|----------------|----------|
| No logs at all | Not using Console.app | Open Console.app and filter by subsystem |
| Model loads but no inference | Task cancelled or not called | Add breakpoint in analyzeAndCreate() |
| Wrong emotions detected | Model needs retraining | Check raw probabilities in logs |
| "Failed to create pixel buffer" | Memory issue or corrupt image | Try simpler image, check available RAM |
| "Not authenticated" error | Spotify token expired | Disconnect and reconnect Spotify |
| No tracks found | Wrong genres selected | Check preferred genres in Profile |
| Slow inference (>1s) | Model not optimized | Check computeUnits setting, profile with Instruments |
| Crashes on device | Out of memory | Reduce image size or model complexity |

## Next Steps for Production

1. **Add User Feedback**
   - Show inference progress ("Analyzing emotion...")
   - Display confidence level to user
   - Allow user to override detected mood

2. **Improve Error Handling**
   - User-friendly error messages
   - Retry logic for network failures
   - Graceful degradation if model fails

3. **Optimize Performance**
   - Cache pixel buffers if analyzing multiple times
   - Batch process if analyzing multiple images
   - Consider quantized model for faster inference

4. **Enhance Accuracy**
   - Use emotion-specific model (FER2013, etc.)
   - Add face detection preprocessing
   - Normalize lighting/contrast before inference

5. **Add Analytics**
   - Track inference times
   - Monitor error rates
   - A/B test different models

## Summary

The enhanced logging should now show you exactly where the process is:
- ✅ Working correctly
- ⚠️ Having issues but continuing
- ❌ Failing completely

**Use Console.app on Mac to see all logs in real-time from your iPhone. This is the key to debugging on physical devices!**

The notifications warnings you're seeing ("Attempting to post will notification with nil userInfo") are unrelated to the Core ML inference - they're just iOS system warnings and can be ignored.
