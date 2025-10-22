//
//  HomeViewModel.swift
//  EmotionPlay
//
//  Fixed crash handling with proper error catching + Widget support
//

import Foundation
import SwiftUI
import UIKit
import OSLog
import WidgetKit

private let logger = Logger(subsystem: "com.emotionplay.viewmodel", category: "Home")

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pickedImageData: Data?
    @Published var detectedMood: Mood?
    @Published var confidence: Double = 0
    @Published var createdPlaylist: Playlist?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isAuthorized: Bool = false
    
    // NEW: Result sheet and error handling
    @Published var showResultSheet = false
    @Published var detectionError: MoodDetectionError? = nil
    
    // Confidence threshold
    private let minConfidence: Double = 0.25

    // MARK: - Dependencies
    let inferencer: MoodInferencer
    let spotifyAuth: SpotifyAuthProviding
    let prefs: UserPreferences
    let history: HistoryStore
    
    // Services
    private let reccoClient = ReccoBeatsClient()
    private var playlistService: SpotifyPlaylistService
    private var moodToPlaylist: MoodToPlaylistService

    // MARK: - Init
    init(
        inferencer: MoodInferencer,
        spotifyAuth: SpotifyAuthProviding,
        prefs: UserPreferences,
        history: HistoryStore
    ) {
        self.inferencer = inferencer
        self.spotifyAuth = spotifyAuth
        self.prefs = prefs
        self.history = history
        self.playlistService = SpotifyPlaylistService(tokenProvider: spotifyAuth)
        self.moodToPlaylist = MoodToPlaylistService(
            recco: reccoClient,
            spotify: playlistService
        )
        self.isAuthorized = spotifyAuth.isAuthorized
    }

    // MARK: - Auth
    func connectSpotify(from presenter: UIViewController) async {
        do {
            try await spotifyAuth.authorize(from: presenter)
            isAuthorized = spotifyAuth.isAuthorized
            errorMessage = nil
        } catch {
            isAuthorized = spotifyAuth.isAuthorized
            errorMessage = "Spotify login failed. Please try again."
        }
    }

    // MARK: - Main Flow
    func analyzeAndCreate() async {
        logger.info("🚀 Starting analyzeAndCreate...")
        
        // Reset state
        errorMessage = nil
        createdPlaylist = nil
        detectedMood = nil
        confidence = 0
        detectionError = nil
        isLoading = true

        // Validation checks
        guard let data = pickedImageData else {
            logger.warning("No image data selected")
            errorMessage = "Please select a photo first."
            isLoading = false
            return
        }

        guard isAuthorized else {
            logger.warning("Not authorized with Spotify")
            errorMessage = "Please connect Spotify in the Profile tab."
            isLoading = false
            return
        }

        do {
            // 1️⃣ VALIDATE: Check if image contains a face (with error handling)
            logger.info("👤 Checking for face in image...")
            
            do {
                let hasFace = try await FaceDetectionHelper.containsFace(imageData: data)
                
                if !hasFace {
                    logger.warning("⚠️ No face detected in image")
                    self.detectionError = .noFaceDetected
                    self.isLoading = false
                    return
                }
                
                logger.info("✅ Face detected, proceeding with mood analysis")
            } catch {
                // If face detection fails, log it but continue anyway
                logger.warning("⚠️ Face detection error (continuing anyway): \(error.localizedDescription)")
            }

            // 2️⃣ Infer mood from image (with error handling)
            logger.info("📸 Starting mood inference...")
            
            let mood: Mood
            let conf: Double
            
            do {
                let result = try await inferencer.infer(fromImageData: data)
                mood = result.0
                conf = result.1
                logger.info("📊 Mood inferred: \(mood.rawValue) with confidence \(String(format: "%.0f", conf * 100))%")
            } catch {
                logger.error("❌ Mood inference failed: \(error.localizedDescription)")
                self.detectionError = .processingFailed("Could not analyze your photo. Please try a different image.")
                self.isLoading = false
                return
            }
            
            // 3️⃣ Check confidence threshold
            if conf < minConfidence {
                logger.warning("⚠️ Confidence too low: \(String(format: "%.0f", conf * 100))%")
                self.detectionError = .lowConfidence(conf)
                self.isLoading = false
                return
            }

            // 4️⃣ Generate playlist via ReccoBeats + Spotify (with error handling)
            logger.info("🎵 Creating playlist for mood: \(mood.rawValue)")
            
            let playlistId: String
            
            do {
                playlistId = try await moodToPlaylist.createPlaylist(for: mood.rawValue)
            } catch {
                logger.error("❌ Playlist creation failed: \(error.localizedDescription)")
                
                // Handle network errors specifically
                if let urlError = error as? URLError {
                    if urlError.code == .notConnectedToInternet {
                        self.errorMessage = "No internet connection. Please check your network."
                    } else {
                        self.errorMessage = "Network error. Please try again."
                    }
                } else {
                    self.errorMessage = "Failed to create playlist: \(error.localizedDescription)"
                }
                
                self.isLoading = false
                return
            }
            
            let playlistURL = URL(string: "https://open.spotify.com/playlist/\(playlistId)")
            let playlistName = "EmotionPlay • \(mood.rawValue.capitalized)"

            // 5️⃣ Save to history
            history.add(
                HistoryItem(
                    date: Date(),
                    mood: mood,
                    playlistName: playlistName,
                    imageData: data,
                    playlistURL: playlistURL,
                    coverURL: nil,
                    confidence: conf
                )
            )

            // 6️⃣ Update UI and show success sheet
            self.detectedMood = mood
            self.confidence = conf
            self.createdPlaylist = Playlist(
                id: playlistId,
                name: playlistName,
                url: playlistURL
            )
            
            // 🆕 7️⃣ Save to widget
            saveToWidget(mood: mood, playlistName: playlistName, confidence: conf, moodCount: history.items.count)
            
            self.isLoading = false
            self.showResultSheet = true
            
            logger.info("✅ Playlist successfully created: \(playlistName)")

        } catch {
            // Global catch-all for any unexpected errors
            logger.error("❌ Unexpected error in analyzeAndCreate: \(error.localizedDescription)")
            
            self.errorMessage = "An unexpected error occurred. Please try again."
            self.isLoading = false
        }
    }
    
    // MARK: - Widget Support
    private func saveToWidget(mood: Mood, playlistName: String, confidence: Double, moodCount: Int) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.emotionplay.shared") else {
            logger.warning("⚠️ Could not access App Group for widget")
            return
        }
        
        let widgetData = WidgetMoodData(
            date: Date(),
            mood: mood,
            playlistName: playlistName,
            confidence: confidence,
            moodCount: moodCount
        )
        
        if let encoded = try? JSONEncoder().encode(widgetData) {
            sharedDefaults.set(encoded, forKey: "latestMood")
            WidgetCenter.shared.reloadAllTimelines()
            logger.info("✅ Widget data saved and reloaded")
        }
    }
    
    // MARK: - Reset for Retake
    func resetForRetake() {
        logger.info("🔄 Resetting for retake...")
        pickedImageData = nil
        detectedMood = nil
        confidence = 0
        createdPlaylist = nil
        errorMessage = nil
        showResultSheet = false
        detectionError = nil
    }
}

// MARK: - Widget Data Model
struct WidgetMoodData: Codable {
    let date: Date
    let mood: Mood
    let playlistName: String
    let confidence: Double
    let moodCount: Int
}
