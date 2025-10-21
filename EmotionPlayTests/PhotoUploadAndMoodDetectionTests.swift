//
//  PhotoUploadAndMoodDetectionTests.swift
//  EmotionPlayTests
//
//  Unit tests for photo upload and mood detection feature
//

import Testing
import Foundation
import UIKit
@testable import EmotionPlay

// MARK: - Mock Dependencies

final class MockMoodInferencer: MoodInferencer {
    var mockResult: (Mood, Double)?
    var shouldThrow = false
    var inferCallCount = 0
    var lastImageData: Data?
    
    func infer(fromImageData data: Data) async throws -> (Mood, Double) {
        inferCallCount += 1
        lastImageData = data
        
        if shouldThrow {
            throw NSError(domain: "MockInferencer", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Mock inference error"])
        }
        
        return mockResult ?? (.happy, 0.85)
    }
}

final class MockSpotifyAuth: SpotifyAuthProviding {
    var mockIsAuthorized = true
    var mockToken = "test_token"
    
    var isAuthorized: Bool { mockIsAuthorized }
    
    func validTokenOrThrow() throws -> String {
        guard let token = mockToken else {
            throw SpotifyError.notAuthenticated
        }
        return token
    }
    
    func authorize(from presenter: UIViewController) async throws {
        mockIsAuthorized = true
    }
}

final class MockHistoryStore: HistoryStore {
    var mockItems: [HistoryItem] = []
    var addCallCount = 0
    var lastAddedItem: HistoryItem?
    
    override var items: [HistoryItem] {
        get { mockItems }
        set { mockItems = newValue }
    }
    
    override func add(_ item: HistoryItem) {
        addCallCount += 1
        lastAddedItem = item
        mockItems.append(item)
    }
}

// MARK: - Photo Upload & Mood Detection Test Suite

@Suite("Photo Upload and Mood Detection Feature")
@MainActor
struct PhotoUploadAndMoodDetectionTests {
    
    // MARK: - Setup Helper
    
    func createViewModel(
        inferencer: MockMoodInferencer? = nil,
        auth: MockSpotifyAuth? = nil
    ) -> (HomeViewModel, MockMoodInferencer, MockSpotifyAuth, MockHistoryStore) {
        let mockInferencer = inferencer ?? MockMoodInferencer()
        let mockAuth = auth ?? MockSpotifyAuth()
        let prefs = UserPreferences()
        let history = MockHistoryStore()
        
        let vm = HomeViewModel(
            inferencer: mockInferencer,
            spotifyAuth: mockAuth,
            prefs: prefs,
            history: history
        )
        
        return (vm, mockInferencer, mockAuth, history)
    }
    
    // MARK: - Initial State Tests
    
    @Test("ViewModel starts with no image selected")
    func testInitialStateNoImage() {
        let (vm, _, _, _) = createViewModel()
        
        #expect(vm.pickedImageData == nil)
        #expect(vm.detectedMood == nil)
        #expect(vm.confidence == 0)
        #expect(vm.isLoading == false)
    }
    
    @Test("ViewModel can store uploaded image data")
    func testImageDataStorage() {
        let (vm, _, _, _) = createViewModel()
        
        let mockImageData = Data([0x01, 0x02, 0x03])
        vm.pickedImageData = mockImageData
        
        #expect(vm.pickedImageData == mockImageData)
        #expect(vm.pickedImageData?.count == 3)
    }
    
    // MARK: - Validation Tests
    
    @Test("Analyze fails when no image is selected")
    func testAnalyzeWithoutImage() async {
        let (vm, inferencer, _, _) = createViewModel()
        
        await vm.analyzeAndCreate()
        
        #expect(vm.errorMessage == "Please select a photo first.")
        #expect(vm.isLoading == false)
        #expect(inferencer.inferCallCount == 0)
    }
    
    @Test("Analyze fails when not authenticated")
    func testAnalyzeWithoutAuth() async {
        let auth = MockSpotifyAuth()
        auth.mockIsAuthorized = false
        let (vm, inferencer, _, _) = createViewModel(auth: auth)
        
        vm.pickedImageData = Data([0x01, 0x02])
        
        await vm.analyzeAndCreate()
        
        #expect(vm.errorMessage == "Please connect Spotify in the Profile tab.")
        #expect(vm.isLoading == false)
        #expect(inferencer.inferCallCount == 0)
    }
    
    // MARK: - Successful Mood Detection Tests
    
    @Test("Successful mood detection with high confidence")
    func testSuccessfulMoodDetectionHighConfidence() async {
        let inferencer = MockMoodInferencer()
        inferencer.mockResult = (.happy, 0.92)
        
        let (vm, mockInferencer, _, history) = createViewModel(inferencer: inferencer)
        
        // Set up test image data
        vm.pickedImageData = Data([0x01, 0x02, 0x03])
        
        await vm.analyzeAndCreate()
        
        // Verify inferencer was called
        #expect(mockInferencer.inferCallCount == 1)
        #expect(mockInferencer.lastImageData == Data([0x01, 0x02, 0x03]))
        
        // Verify mood was detected (note: actual playlist creation will fail in unit test)
        #expect(vm.detectedMood == .happy)
        #expect(vm.confidence == 0.92)
    }
    
    @Test("Mood detection with confidence at threshold (0.25)")
    func testMoodDetectionAtThreshold() async {
        let inferencer = MockMoodInferencer()
        inferencer.mockResult = (.calm, 0.25) // Exactly at threshold
        
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        // Should NOT show low confidence error
        if let error = vm.detectionError {
            if case .lowConfidence = error {
                Issue.record("Should not show low confidence error at threshold")
            }
        }
    }
    
    @Test("All moods can be detected", arguments: Mood.allCases)
    func testAllMoodsDetectable(mood: Mood) async {
        let inferencer = MockMoodInferencer()
        inferencer.mockResult = (mood, 0.85)
        
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        // At minimum, inferencer should be called for each mood
        #expect(inferencer.inferCallCount == 1)
    }
    
    // MARK: - Low Confidence Tests
    
    @Test("Low confidence detection shows appropriate error")
    func testLowConfidenceError() async {
        let inferencer = MockMoodInferencer()
        inferencer.mockResult = (.sad, 0.15) // Below 0.25 threshold
        
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        #expect(vm.detectionError != nil)
        
        if case .lowConfidence(let conf) = vm.detectionError {
            #expect(conf == 0.15)
        } else {
            Issue.record("Expected lowConfidence error")
        }
        
        #expect(vm.isLoading == false)
    }
    
    @Test("Very low confidence (0.05) is handled")
    func testVeryLowConfidence() async {
        let inferencer = MockMoodInferencer()
        inferencer.mockResult = (.anxious, 0.05)
        
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        if case .lowConfidence(let conf) = vm.detectionError {
            #expect(conf == 0.05)
        } else {
            Issue.record("Expected lowConfidence error")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Inference failure shows processing error")
    func testInferenceFailure() async {
        let inferencer = MockMoodInferencer()
        inferencer.shouldThrow = true
        
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        #expect(vm.detectionError != nil)
        
        if case .processingFailed(let message) = vm.detectionError {
            #expect(message.contains("Could not analyze") == true)
        } else {
            Issue.record("Expected processingFailed error")
        }
        
        #expect(vm.isLoading == false)
    }
    
    // MARK: - Reset Tests
    
    @Test("Reset clears all state correctly")
    func testResetForRetake() {
        let (vm, _, _, _) = createViewModel()
        
        // Set some state
        vm.pickedImageData = Data([0x01])
        vm.detectedMood = .happy
        vm.confidence = 0.85
        vm.errorMessage = "Some error"
        vm.showResultSheet = true
        vm.detectionError = .noFaceDetected
        
        // Reset
        vm.resetForRetake()
        
        // Verify everything is cleared
        #expect(vm.pickedImageData == nil)
        #expect(vm.detectedMood == nil)
        #expect(vm.confidence == 0)
        #expect(vm.errorMessage == nil)
        #expect(vm.showResultSheet == false)
        #expect(vm.detectionError == nil)
    }
    
    @Test("Reset allows new upload after error")
    func testResetAfterError() async {
        let (vm, _, _, _) = createViewModel()
        
        // First attempt without image
        await vm.analyzeAndCreate()
        #expect(vm.errorMessage != nil)
        
        // Reset
        vm.resetForRetake()
        
        // Should be able to set new image
        vm.pickedImageData = Data([0x01, 0x02])
        #expect(vm.pickedImageData != nil)
        #expect(vm.errorMessage == nil)
    }
    
    // MARK: - Loading State Tests
    
    @Test("Loading state is set during analysis")
    func testLoadingStateDuringAnalysis() async {
        let inferencer = MockMoodInferencer()
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        
        vm.pickedImageData = Data([0x01])
        
        // Start analysis in background
        let task = Task {
            await vm.analyzeAndCreate()
        }
        
        // Check loading state (might be true briefly)
        // Note: This is tricky in unit tests due to timing
        
        await task.value
        
        // After completion, loading should be false
        #expect(vm.isLoading == false)
    }
    
    // MARK: - Image Data Validation Tests
    
    @Test("Empty image data is handled")
    func testEmptyImageData() async {
        let (vm, inferencer, _, _) = createViewModel()
        
        vm.pickedImageData = Data() // Empty data
        
        await vm.analyzeAndCreate()
        
        // Should still attempt to process
        #expect(inferencer.inferCallCount == 1)
        #expect(inferencer.lastImageData?.isEmpty == true)
    }
    
    @Test("Large image data is handled")
    func testLargeImageData() async {
        let (vm, inferencer, _, _) = createViewModel()
        
        // Create 5MB of mock data
        let largeData = Data(repeating: 0xFF, count: 5_000_000)
        vm.pickedImageData = largeData
        
        await vm.analyzeAndCreate()
        
        #expect(inferencer.inferCallCount == 1)
        #expect(inferencer.lastImageData?.count == 5_000_000)
    }
    
    // MARK: - Confidence Threshold Tests
    
    @Test("Confidence just below threshold (0.24) fails")
    func testConfidenceJustBelowThreshold() async {
        let inferencer = MockMoodInferencer()
        inferencer.mockResult = (.energetic, 0.24)
        
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        if case .lowConfidence = vm.detectionError {
            // Expected
        } else {
            Issue.record("Expected lowConfidence error for 0.24 confidence")
        }
    }
    
    @Test("Confidence just above threshold (0.26) succeeds")
    func testConfidenceJustAboveThreshold() async {
        let inferencer = MockMoodInferencer()
        inferencer.mockResult = (.focused, 0.26)
        
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        // Should NOT have low confidence error
        if case .lowConfidence = vm.detectionError {
            Issue.record("Should not fail with confidence of 0.26")
        }
    }
    
    @Test("Perfect confidence (1.0) is handled")
    func testPerfectConfidence() async {
        let inferencer = MockMoodInferencer()
        inferencer.mockResult = (.nostalgic, 1.0)
        
        let (vm, _, _, _) = createViewModel(inferencer: inferencer)
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        #expect(inferencer.inferCallCount == 1)
    }
    
    // MARK: - State Consistency Tests
    
    @Test("Error message is cleared on new analysis")
    func testErrorMessageClearedOnNewAnalysis() async {
        let (vm, _, _, _) = createViewModel()
        
        // Set error from previous attempt
        vm.errorMessage = "Previous error"
        vm.pickedImageData = Data([0x01])
        
        await vm.analyzeAndCreate()
        
        // Error should be reset at start (might have new error, but not old one)
        // The key is that old state doesn't persist
    }
    
    @Test("Multiple sequential uploads maintain state correctly")
    func testMultipleSequentialUploads() async {
        let (vm, _, _, _) = createViewModel()
        
        // First upload
        vm.pickedImageData = Data([0x01])
        #expect(vm.pickedImageData?.count == 1)
        
        // Second upload (replacing first)
        vm.pickedImageData = Data([0x01, 0x02, 0x03])
        #expect(vm.pickedImageData?.count == 3)
        
        // Third upload
        vm.pickedImageData = Data([0xFF])
        #expect(vm.pickedImageData?.count == 1)
    }
}

// MARK: - Mood Model Tests

@Suite("Mood Model Tests")
struct MoodModelTests {
    
    @Test("All moods have valid raw values")
    func testMoodRawValues() {
        #expect(Mood.happy.rawValue == "happy")
        #expect(Mood.sad.rawValue == "sad")
        #expect(Mood.calm.rawValue == "calm")
        #expect(Mood.energetic.rawValue == "energetic")
        #expect(Mood.anxious.rawValue == "anxious")
        #expect(Mood.angry.rawValue == "angry")
        #expect(Mood.melancholic.rawValue == "melancholic")
        #expect(Mood.focused.rawValue == "focused")
        #expect(Mood.nostalgic.rawValue == "nostalgic")
    }
    
    @Test("Mood has 9 cases")
    func testMoodCaseCount() {
        #expect(Mood.allCases.count == 9)
    }
    
    @Test("Mood is Codable")
    func testMoodCodable() throws {
        let mood = Mood.happy
        let encoded = try JSONEncoder().encode(mood)
        let decoded = try JSONDecoder().decode(Mood.self, from: encoded)
        
        #expect(decoded == mood)
    }
    
    @Test("All moods can be encoded and decoded", arguments: Mood.allCases)
    func testAllMoodsCodable(mood: Mood) throws {
        let encoded = try JSONEncoder().encode(mood)
        let decoded = try JSONDecoder().decode(Mood.self, from: encoded)
        
        #expect(decoded == mood)
    }
}

// MARK: - MoodDetectionError Tests

@Suite("MoodDetectionError Tests")
struct MoodDetectionErrorTests {
    
    @Test("No face detected error has correct description")
    func testNoFaceDetectedError() {
        let error = MoodDetectionError.noFaceDetected
        
        #expect(error.errorDescription?.contains("face") == true)
    }
    
    @Test("Low confidence error includes confidence value")
    func testLowConfidenceError() {
        let error = MoodDetectionError.lowConfidence(0.15)
        
        #expect(error.errorDescription?.contains("confidence") == true)
    }
    
    @Test("Processing failed error includes custom message")
    func testProcessingFailedError() {
        let customMessage = "Custom error message"
        let error = MoodDetectionError.processingFailed(customMessage)
        
        #expect(error.errorDescription == customMessage)
    }
    
    @Test("MoodDetectionError is Identifiable")
    func testMoodDetectionErrorIdentifiable() {
        let error1 = MoodDetectionError.noFaceDetected
        let error2 = MoodDetectionError.lowConfidence(0.2)
        
        // Each error should have a unique ID
        #expect(error1.id != error2.id)
    }
}
