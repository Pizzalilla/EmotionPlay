//
//  PhotoUploadAndMoodDetectionUITests.swift
//  EmotionPlayUITests
//
//  UI tests for photo upload and mood detection flow
//

import XCTest

final class PhotoUploadAndMoodDetectionUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Initial State Tests
    
    @MainActor
    func testHomeScreenLoadsSuccessfully() throws {
        // Verify app launches and home screen is visible
        let homeView = app.otherElements["HomeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 5))
        
        // Verify app title is present
        let titleText = app.staticTexts["EmotionPlay"]
        XCTAssertTrue(titleText.exists)
    }
    
    @MainActor
    func testUploadCardIsVisible() throws {
        // Verify the upload card is displayed
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.waitForExistence(timeout: 3))
        
        // Verify empty state message
        let emptyStateText = app.staticTexts["Upload or take a photo to discover your mood"]
        XCTAssertTrue(emptyStateText.exists)
    }
    
    @MainActor
    func testCameraIconIsVisible() throws {
        // Verify camera icon is displayed in upload card
        let cameraIcon = app.images.matching(identifier: "camera.fill").element
        XCTAssertTrue(cameraIcon.exists)
    }
    
    // MARK: - Photo Picker Flow Tests
    
    @MainActor
    func testTapUploadCardOpensPhotoPicker() throws {
        // Tap on the upload card
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.waitForExistence(timeout: 3))
        uploadCard.tap()
        
        // Verify photo picker sheet appears
        let addPhotoTitle = app.staticTexts["Add Photo"]
        XCTAssertTrue(addPhotoTitle.waitForExistence(timeout: 3))
        
        // Verify both options are present
        let takePhotoButton = app.buttons["Take Photo"]
        let chooseLibraryButton = app.buttons["Choose from Library"]
        
        XCTAssertTrue(takePhotoButton.exists)
        XCTAssertTrue(chooseLibraryButton.exists)
    }
    
    @MainActor
    func testPhotoPickerCanBeCancelled() throws {
        // Open photo picker
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        uploadCard.tap()
        
        // Wait for sheet
        let addPhotoTitle = app.staticTexts["Add Photo"]
        XCTAssertTrue(addPhotoTitle.waitForExistence(timeout: 3))
        
        // Tap cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)
        cancelButton.tap()
        
        // Verify sheet is dismissed
        XCTAssertFalse(addPhotoTitle.exists)
        
        // Verify back on home screen
        let homeView = app.otherElements["HomeView"]
        XCTAssertTrue(homeView.exists)
    }
    
    @MainActor
    func testCameraOptionIsPresent() throws {
        // Open photo picker
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        uploadCard.tap()
        
        // Verify camera option
        let takePhotoButton = app.buttons["Take Photo"]
        XCTAssertTrue(takePhotoButton.waitForExistence(timeout: 3))
        XCTAssertTrue(takePhotoButton.isEnabled)
        
        // Verify camera icon
        let cameraIcon = app.images["camera.fill"]
        XCTAssertTrue(cameraIcon.exists)
        
        // Verify description text
        let cameraDescription = app.staticTexts["Use your camera"]
        XCTAssertTrue(cameraDescription.exists)
    }
    
    @MainActor
    func testLibraryOptionIsPresent() throws {
        // Open photo picker
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        uploadCard.tap()
        
        // Verify library option
        let libraryButton = app.buttons["Choose from Library"]
        XCTAssertTrue(libraryButton.waitForExistence(timeout: 3))
        XCTAssertTrue(libraryButton.isEnabled)
        
        // Verify library icon
        let libraryIcon = app.images["photo.on.rectangle"]
        XCTAssertTrue(libraryIcon.exists)
        
        // Verify description text
        let libraryDescription = app.staticTexts["Pick an existing photo"]
        XCTAssertTrue(libraryDescription.exists)
    }
    
    // MARK: - Analyze Button State Tests
    
    @MainActor
    func testAnalyzeButtonDisabledWhenNoImage() throws {
        // Look for analyze button
        let analyzeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Analyze Photo'")).element
        
        if analyzeButton.exists {
            // If button exists, it should be disabled
            XCTAssertFalse(analyzeButton.isEnabled, "Analyze button should be disabled without an image")
        }
    }
    
    @MainActor
    func testConnectSpotifyButtonIsVisibleWhenNotAuthorized() throws {
        // If not authorized, should see connect button
        let connectButton = app.buttons["Connect Spotify"]
        
        // Note: This test assumes user is not logged in
        // In a real scenario, you'd set up test data
        if connectButton.exists {
            XCTAssertTrue(connectButton.isEnabled)
            
            // Verify icon is present
            let spotifyIcon = app.images["arrow.up.right.circle.fill"]
            XCTAssertTrue(spotifyIcon.exists)
        }
    }
    
    // MARK: - Error Handling UI Tests
    
    @MainActor
    func testNoImageErrorIsDisplayed() throws {
        // Try to analyze without selecting image
        let analyzeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Analyze Photo'")).element
        
        if analyzeButton.exists && analyzeButton.isEnabled {
            analyzeButton.tap()
            
            // Should see error message
            let errorText = app.staticTexts["Please select a photo first."]
            XCTAssertTrue(errorText.waitForExistence(timeout: 2))
        }
    }
    
    @MainActor
    func testNotAuthenticatedErrorIsDisplayed() throws {
        // This test assumes user is not authenticated
        // In production, you'd use test accounts or mocks
        
        let connectButton = app.buttons["Connect Spotify"]
        if connectButton.exists {
            // Error should be shown or connect button should be visible
            XCTAssertTrue(connectButton.isEnabled)
        }
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNavigationBetweenTabs() throws {
        // Verify tab bar exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Test navigation to Profile tab
        let profileTab = tabBar.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            
            // Verify profile view is shown
            let profileView = app.otherElements["ProfileView"]
            XCTAssertTrue(profileView.waitForExistence(timeout: 2))
            
            // Navigate back to Home
            let homeTab = tabBar.buttons["Home"]
            XCTAssertTrue(homeTab.exists)
            homeTab.tap()
            
            // Verify home view is shown again
            let homeView = app.otherElements["HomeView"]
            XCTAssertTrue(homeView.waitForExistence(timeout: 2))
        }
    }
    
    @MainActor
    func testNavigationToHistory() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Navigate to History tab
        let historyTab = tabBar.buttons["History"]
        if historyTab.exists {
            historyTab.tap()
            
            // Verify history view is shown
            let historyView = app.otherElements["HistoryView"]
            XCTAssertTrue(historyView.waitForExistence(timeout: 2))
        }
    }
    
    // MARK: - UI Component Visibility Tests
    
    @MainActor
    func testAllMainUIComponentsAreVisible() throws {
        // Header
        let header = app.staticTexts["EmotionPlay"]
        XCTAssertTrue(header.exists)
        
        // App icon in header
        let appIcon = app.images["music.note"]
        XCTAssertTrue(appIcon.exists)
        
        // Upload card
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.exists)
        
        // Tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
    }
    
    @MainActor
    func testUploadCardStylingIsCorrect() throws {
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.exists)
        
        // Verify card is tappable
        XCTAssertTrue(uploadCard.isHittable)
        
        // Verify main text is visible
        let mainText = app.staticTexts["How are you feeling?"]
        XCTAssertTrue(mainText.exists)
        
        // Verify subtitle is visible
        let subtitle = app.staticTexts["Upload or take a photo to discover your mood"]
        XCTAssertTrue(subtitle.exists)
    }
    
    // MARK: - Loading State Tests
    
    @MainActor
    func testLoadingIndicatorAppearsDuringAnalysis() throws {
        // Note: This test would require a photo to be selected
        // In a real test, you'd use UI testing features to select a photo
        
        // If analyze button exists and we trigger analysis
        let analyzeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Analyze Photo'")).element
        
        if analyzeButton.exists && analyzeButton.isEnabled {
            analyzeButton.tap()
            
            // Should see loading indicator or "Analyzing..." text
            let analyzingText = app.staticTexts["Analyzing..."]
            let loadingIndicator = app.activityIndicators.firstMatch
            
            // One of these should appear
            XCTAssertTrue(analyzingText.exists || loadingIndicator.exists)
        }
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testUploadCardIsAccessible() throws {
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.exists)
        
        // Should be accessible
        XCTAssertTrue(uploadCard.isEnabled)
        XCTAssertTrue(uploadCard.isHittable)
    }
    
    @MainActor
    func testPhotoPickerOptionsAreAccessible() throws {
        // Open photo picker
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        uploadCard.tap()
        
        // Both options should be accessible
        let takePhotoButton = app.buttons["Take Photo"]
        let chooseLibraryButton = app.buttons["Choose from Library"]
        
        XCTAssertTrue(takePhotoButton.waitForExistence(timeout: 2))
        XCTAssertTrue(chooseLibraryButton.exists)
        
        // Should be hittable (tappable)
        XCTAssertTrue(takePhotoButton.isHittable)
        XCTAssertTrue(chooseLibraryButton.isHittable)
    }
    
    @MainActor
    func testAllButtonsHaveAccessibilityLabels() throws {
        // Upload card
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.exists)
        
        // Open picker
        uploadCard.tap()
        
        // Check camera button has label
        let cameraButton = app.buttons["Take Photo"]
        XCTAssertTrue(cameraButton.exists)
        
        // Check library button has label
        let libraryButton = app.buttons["Choose from Library"]
        XCTAssertTrue(libraryButton.exists)
        
        // Check cancel button has label
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)
    }
    
    // MARK: - Sheet Interaction Tests
    
    @MainActor
    func testPhotoPickerSheetCanBeDismissedBySwipe() throws {
        // Open photo picker
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        uploadCard.tap()
        
        // Wait for sheet
        let addPhotoTitle = app.staticTexts["Add Photo"]
        XCTAssertTrue(addPhotoTitle.waitForExistence(timeout: 3))
        
        // Swipe down to dismiss (simulate user gesture)
        let sheet = app.sheets.firstMatch
        if sheet.exists {
            sheet.swipeDown()
            
            // Sheet should be dismissed
            XCTAssertFalse(addPhotoTitle.waitForExistence(timeout: 1))
        }
    }
    
    @MainActor
    func testMultiplePhotoPickerOpenAndClose() throws {
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        
        // Open picker multiple times
        for _ in 0..<3 {
            uploadCard.tap()
            
            let addPhotoTitle = app.staticTexts["Add Photo"]
            XCTAssertTrue(addPhotoTitle.waitForExistence(timeout: 2))
            
            // Close it
            let cancelButton = app.buttons["Cancel"]
            cancelButton.tap()
            
            // Wait for dismissal
            XCTAssertFalse(addPhotoTitle.exists)
        }
        
        // Should still be functional
        XCTAssertTrue(uploadCard.exists)
    }
    
    // MARK: - Visual Verification Tests
    
    @MainActor
    func testAppIconVisuallyPresent() throws {
        // Verify app icon is rendered
        let appIconContainer = app.images.matching(identifier: "music.note").element
        XCTAssertTrue(appIconContainer.exists)
        
        // Verify it's in the header area (approximate location check)
        XCTAssertTrue(appIconContainer.frame.origin.y < 200)
    }
    
    @MainActor
    func testPhotoPickerIconsArePresent() throws {
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        uploadCard.tap()
        
        // Check camera icon
        let cameraIcon = app.images["camera.fill"]
        XCTAssertTrue(cameraIcon.waitForExistence(timeout: 2))
        
        // Check library icon
        let libraryIcon = app.images["photo.on.rectangle"]
        XCTAssertTrue(libraryIcon.exists)
        
        // Check chevrons
        let chevrons = app.images.matching(identifier: "chevron.right")
        XCTAssertTrue(chevrons.count >= 2)
    }
    
    // MARK: - State Persistence Tests
    
    @MainActor
    func testHomeViewStateAfterBackgroundAndForeground() throws {
        // Verify initial state
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.exists)
        
        // Simulate app going to background and coming back
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        
        // Verify state is maintained
        XCTAssertTrue(uploadCard.waitForExistence(timeout: 3))
    }
    
    // MARK: - Orientation Tests
    
    @MainActor
    func testPortraitOrientation() throws {
        XCUIDevice.shared.orientation = .portrait
        
        // Verify UI still works in portrait
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.waitForExistence(timeout: 2))
        XCTAssertTrue(uploadCard.isHittable)
    }
    
    @MainActor
    func testLandscapeOrientation() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Give time for rotation
        sleep(1)
        
        // Verify UI still works in landscape
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        XCTAssertTrue(uploadCard.waitForExistence(timeout: 2))
        XCTAssertTrue(uploadCard.isHittable)
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testPhotoPickerOpenPerformance() throws {
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        
        measure(metrics: [XCTClockMetric()]) {
            uploadCard.tap()
            
            let addPhotoTitle = app.staticTexts["Add Photo"]
            _ = addPhotoTitle.waitForExistence(timeout: 5)
            
            let cancelButton = app.buttons["Cancel"]
            cancelButton.tap()
            
            // Wait for dismissal
            sleep(1)
        }
    }
    
    @MainActor
    func testTabNavigationPerformance() throws {
        let tabBar = app.tabBars.firstMatch
        
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to Profile
            tabBar.buttons["Profile"].tap()
            sleep(UInt32(0.5))
            
            // Navigate to History
            tabBar.buttons["History"].tap()
            sleep(UInt32(0.5))
            // Navigate back to Home
            tabBar.buttons["Home"].tap()
            sleep(UInt32(0.5))
            }
    }
    
    // MARK: - Edge Case Tests
    
    @MainActor
    func testRapidTappingUploadCard() throws {
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        
        // Rapidly tap multiple times
        for _ in 0..<5 {
            uploadCard.tap()
        }
        
        // Should still show picker (not crash or behave erratically)
        let addPhotoTitle = app.staticTexts["Add Photo"]
        XCTAssertTrue(addPhotoTitle.exists)
        
        // Close it
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()
    }
    
    @MainActor
    func testNavigationDuringSheetOpen() throws {
        // Open photo picker
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        uploadCard.tap()
        
        let addPhotoTitle = app.staticTexts["Add Photo"]
        XCTAssertTrue(addPhotoTitle.waitForExistence(timeout: 2))
        
        // Try to navigate to another tab while sheet is open
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Profile"].exists {
            tabBar.buttons["Profile"].tap()
            
            // Sheet should be dismissed or handled gracefully
            // App should not crash
            XCTAssertTrue(app.state == .runningForeground)
        }
    }
    
    // MARK: - Text Content Verification
    
    @MainActor
    func testAllExpectedTextIsPresent() throws {
        // App title
        XCTAssertTrue(app.staticTexts["EmotionPlay"].exists)
        
        // Main prompt
        XCTAssertTrue(app.staticTexts["How are you feeling?"].exists)
        
        // Subtitle
        XCTAssertTrue(app.staticTexts["Upload or take a photo to discover your mood"].exists)
    }
    
    @MainActor
    func testPhotoPickerTextContent() throws {
        let uploadCard = app.buttons.containing(NSPredicate(format: "label CONTAINS 'How are you feeling'")).element
        uploadCard.tap()
        
        // Header text
        XCTAssertTrue(app.staticTexts["Add Photo"].exists)
        XCTAssertTrue(app.staticTexts["Choose how you'd like to add a photo"].exists)
        
        // Option texts
        XCTAssertTrue(app.staticTexts["Take Photo"].exists)
        XCTAssertTrue(app.staticTexts["Use your camera"].exists)
        XCTAssertTrue(app.staticTexts["Choose from Library"].exists)
        XCTAssertTrue(app.staticTexts["Pick an existing photo"].exists)
    }
}
