//
//  HomeViewModel.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

import Foundation
import SwiftUI
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.emotionplay.viewmodel", category: "Home")

/// Glue between the Home screen, the mood inferencer, and Spotify client.
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
    private let music: (any MusicProviderClient & Recommender)
    let prefs: UserPreferences
    let history: HistoryStore

    // MARK: - Init
    init(
        inferencer: MoodInferencer,
        music: (any MusicProviderClient & Recommender),
        prefs: UserPreferences,
        history: HistoryStore
    ) {
        self.inferencer = inferencer
        self.music = music
        self.prefs = prefs
        self.history = history
        self.isAuthorized = music.isAuthorized
    }

  // MARK: - Auth
  /// Starts Spotify login from a given presenter and updates `isAuthorized`.
  @MainActor
  func connectSpotify(from presenter: UIViewController) async {
    do {
      try await music.authorize(from: presenter)
      self.isAuthorized = music.isAuthorized
      self.errorMessage = nil
    } catch {
      self.isAuthorized = music.isAuthorized
      self.errorMessage = "Spotify login failed. Please try again."
    }
  }

  // MARK: - Main flow
  /// Infer mood → get track URIs → create playlist → add tracks → update UI.
  @MainActor
  func analyzeAndCreate() async {
    logger.info("🚀 Starting analyzeAndCreate...")
    errorMessage = nil
    createdPlaylist = nil
    detectedMood = nil
    confidence = 0
    isLoading = true

    guard let data = pickedImageData else {
      logger.warning("⚠️ No image data selected")
      errorMessage = "Please select a photo first."
      isLoading = false
      return
    }
    logger.info("✅ Image data available: \(data.count) bytes")
    
    guard isAuthorized else {
      logger.warning("⚠️ Not authorized with Spotify")
      errorMessage = "Please connect Spotify in the Profile tab."
      isLoading = false
      return
    }
    logger.info("✅ Spotify authorized")

    do {
      // 1) Infer mood from image
      logger.info("🔮 Starting mood inference...")
      let (mood, conf) = try await inferencer.infer(fromImageData: data)
      logger.info("✅ Mood inferred: \(mood.rawValue) with confidence \(String(format: "%.2f", conf))")
      print("🎯 HomeViewModel: Detected \(mood.rawValue) (\(Int(conf * 100))%)")
      // TEMP while testing:
      // let (mood, conf) = (.happy, 0.72)
      

      // 2) Get user-preferred genres (or let Spotify use top artists' genres)
      let genres: [String] = Array(prefs.preferredGenres)
      if genres.isEmpty {
        logger.info("🎵 No preferred genres set - will use genres from your top artists")
      } else {
        logger.info("🎵 Using preferred genres: \(genres.joined(separator: ", "))")
      }

      // 3) Fetch PERSONALIZED recommendations based on your listening history
      logger.info("🔍 Fetching personalized track recommendations...")
      logger.info("💡 Using your top artists and tracks as seeds")
      let trackURIs = try await music.recommendTrackURIs(
        for: mood,
        preferredGenres: genres,
        limit: 20
      )
      logger.info("✅ Got \(trackURIs.count) personalized track URIs")

      // 4) Create playlist & add tracks
      let playlistName = "EmotionPlay • \(mood.rawValue.capitalized)"
      logger.info("📝 Creating playlist: \(playlistName)")
      let (playlistID, externalURL) = try await music.createPlaylist(
        name: playlistName,
        description: "Personalized \(mood.rawValue) playlist based on your listening history • Created by EmotionPlay",
        isPublic: false
      )
      logger.info("✅ Playlist created with ID: \(playlistID)")

      if !trackURIs.isEmpty {
        logger.info("➕ Adding \(trackURIs.count) tracks to playlist...")
        try await music.addTracks(to: playlistID, uris: trackURIs)
        logger.info("✅ Tracks added successfully")
      } else {
        logger.warning("⚠️ No tracks to add")
      }

      // 5) Persist to history (optional)
      history.add(
          HistoryItem(
            date: Date(),
            mood: mood,
            playlistName: playlistName,
            imageData: data,
            playlistURL: externalURL,
            coverURL: nil,
            confidence: conf
          )
      )


      // 6) Update UI
      logger.info("🎉 Success! Updating UI...")
      self.detectedMood = mood
      self.confidence = conf
      self.createdPlaylist = Playlist(id: playlistID, name: playlistName, url: externalURL)
      self.isLoading = false
      logger.info("✅ analyzeAndCreate completed successfully")

    } catch {
      logger.error("❌ analyzeAndCreate failed: \(error.localizedDescription)")
      self.errorMessage = "Failed: \(error.localizedDescription)"
      self.isLoading = false
      print("❌ HomeViewModel analyzeAndCreate error:", error)
    }
  }
}
