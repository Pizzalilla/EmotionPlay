//
//  HomeViewModel.swift
//  EmotionPlay
//
//  Updated for ReccoBeats + Spotify integration
//

import Foundation
import SwiftUI
import UIKit
import OSLog

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
        errorMessage = nil
        createdPlaylist = nil
        detectedMood = nil
        confidence = 0
        isLoading = true

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
            // 1️⃣ Infer mood from image
            let (mood, conf) = try await inferencer.infer(fromImageData: data)
            logger.info("Mood inferred: \(mood.rawValue) with confidence \(String(format: "%.2f", conf))")

            // 2️⃣ Generate playlist via ReccoBeats + Spotify
            logger.info("Fetching recommendations via ReccoBeats and building playlist...")
            let playlistId = try await moodToPlaylist.createPlaylist(for: mood.rawValue)
            let playlistURL = URL(string: "https://open.spotify.com/playlist/\(playlistId)")

            // 3️⃣ Save to history
            history.add(
                HistoryItem(
                    date: Date(),
                    mood: mood,
                    playlistName: "EmotiPlay – \(mood.rawValue.capitalized)",
                    imageData: data,
                    playlistURL: playlistURL,
                    coverURL: nil,
                    confidence: conf
                )
            )

            // 4️⃣ Update UI
            self.detectedMood = mood
            self.confidence = conf
            self.createdPlaylist = Playlist(id: playlistId,
                                            name: "EmotiPlay – \(mood.rawValue.capitalized)",
                                            url: playlistURL)
            self.isLoading = false
            logger.info("✅ Playlist successfully created!")

        } catch {
            logger.error("❌ analyzeAndCreate failed: \(error.localizedDescription)")
            errorMessage = "Failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
