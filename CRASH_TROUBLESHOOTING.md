# Crash Troubleshooting Guide

## Common Crash Causes & Fixes

### 1. Sheet Presentation Crash

**Symptom:** App crashes when trying to show error alert

**Cause:** Presenting sheet while another sheet is active

**Fix:** Make sure only ONE sheet is presented at a time

Check `HomeView.swift` - make sure sheets don't conflict:

```swift
// ✅ CORRECT - Each sheet has unique condition
.sheet(isPresented: $vm.showResultSheet) { ... }
.sheet(item: $vm.detectionError) { ... }
.sheet(isPresented: $showCamera) { ... }

// ❌ WRONG - Multiple sheets with same state
.sheet(isPresented: $showSheet) { ResultView() }
.sheet(isPresented: $showSheet) { ErrorView() }  // CRASH!
```

---

### 2. Face Detection Crash

**Symptom:** Crash when analyzing non-face photo

**Possible Cause:** Vision framework error not caught

**Fix Applied:** Added try-catch around face detection

```swift
do {
    let hasFace = try await FaceDetectionHelper.containsFace(imageData: data)
    if !hasFace {
        self.detectionError = .noFaceDetected  // Show error
        return
    }
} catch {
    // Don't crash - just log and continue
    logger.warning("Face detection failed, continuing anyway")
}
```

---

### 3. Core ML Model Crash

**Symptom:** Crash during mood prediction

**Possible Causes:**
- Model file missing
- Wrong image size
- Memory issue

**Debug Steps:**

1. Check console for this output:
```
✅ Model loaded: 360x360
✅ UIImage created
✅ CGImage obtained
✅ Pixel buffer created
🔮 Running model prediction...
```

If it stops before "Prediction completed", the model is crashing.

2. Test with different image:
   - Try smaller image (< 1MB)
   - Try PNG instead of JPEG
   - Try image from camera vs library

---

### 4. Memory Crash

**Symptom:** Crash with large images

**Fix:** Images are now resized in DirectCoreMLInferencer

---

## 🐛 Debug Mode

### Enable Detailed Logging

The app already has comprehensive logging. To see it:

1. Open Xcode
2. Run app on device
3. Open Console (bottom panel)
4. Filter by "emotionplay"

You should see:
```
[emotionplay.viewmodel.Home] 🚀 Starting analyzeAndCreate...
[emotionplay.inference.CoreML] 🖼️ Starting inference...
[emotionplay.facedetection.Validation] 👤 Checking for face...
```

---

## 🔍 Step-by-Step Debug

### Test 1: Verify Model Works
1. Upload a **clear face photo**
2. Does it analyze successfully?
   - YES → Model is fine
   - NO → Model issue

### Test 2: Test Face Detection
1. Upload a **landscape photo** (no face)
2. Watch console for:
```
👤 Checking for face in image...
⚠️ No face detected in image
```
3. Does error alert show?
   - YES → Working!
   - NO → Sheet presentation issue

### Test 3: Test Low Confidence
1. Upload **blurry face photo**
2. Watch console for:
```
📊 Mood inferred: calm with confidence 18%
⚠️ Confidence too low: 18%
```
3. Does error alert show?
   - YES → Working!
   - NO → Sheet presentation issue

---

## 🚨 Emergency Fallback: Disable Face Detection

If face detection is causing crashes, temporarily disable it:

In `HomeViewModel.swift`, comment out face detection:

```swift
// TEMPORARY: Skip face detection
/*
do {
    let hasFace = try await FaceDetectionHelper.containsFace(imageData: data)
    if !hasFace {
        self.detectionError = .noFaceDetected
        self.isLoading = false
        return
    }
} catch {
    logger.warning("⚠️ Face detection error: \(error.localizedDescription)")
}
*/

// Continue directly to mood inference
logger.info("📸 Starting mood inference (face detection skipped)...")
```

---

## 📱 Specific Error Messages

When app crashes, look for:

### "Thread 1: signal SIGABRT"
- Sheet presentation conflict
- Fix: Check HomeView sheets

### "Unexpectedly found nil"
- Optional unwrapping crash
- Fix: Check force unwraps (!)

### "EXC_BAD_ACCESS"
- Memory issue
- Fix: Large image - already handled

### "precondition failure"
- Vision framework error
- Fix: Already wrapped in try-catch

---

## ✅ Current Safety Features

The updated code has:

1. ✅ Multiple try-catch blocks
2. ✅ Graceful error handling
3. ✅ Detailed logging
4. ✅ No force unwraps
5. ✅ Memory-efficient image processing
6. ✅ Thread-safe operations
7. ✅ Proper async/await
8. ✅ Error type checking

---

## 🎯 What to Check Now

1. **Build & Run**
2. **Check Console** for error logs
3. **Try each scenario:**
   - ✓ Clear face photo
   - ✓ No face photo
   - ✓ Blurry photo

4. **Report back:**
   - Which scenario crashes?
   - What's the console output?
   - What's the crash message?

---

## 💡 Alternative: Simple Error Message

If sheets keep crashing, use simple alerts instead:

```swift
// Instead of sheet
.sheet(item: $vm.detectionError) { error in
    ErrorAlertView(...)
}

// Use alert
.alert("Error", isPresented: .constant(vm.detectionError != nil)) {
    Button("OK") { vm.detectionError = nil }
} message: {
    Text(vm.detectionError?.message ?? "Unknown error")
}
```

This is simpler and less likely to crash.

---

## 🆘 If Still Crashing

Send me:
1. Console output (copy/paste)
2. Which photo type causes crash
3. Crash error message from Xcode

I'll help you fix it!
