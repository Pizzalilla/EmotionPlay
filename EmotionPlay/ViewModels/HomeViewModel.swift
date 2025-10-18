//
//  HomeViewModel.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

import Foundation
import SwiftUI
import UIKit

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
    errorMessage = nil
    createdPlaylist = nil
    detectedMood = nil
    confidence = 0
    isLoading = true

    guard let data = pickedImageData else {
      errorMessage = "Please select a photo first."
      isLoading = false
      return
    }
    guard isAuthorized else {
      errorMessage = "Please connect Spotify in the Profile tab."
      isLoading = false
      return
    }

    do {
      // 1) Infer mood from image (replace with your real remote call if needed)
      let (mood, conf) = try await inferencer.infer(fromImageData: data)
      // TEMP while testing:
      // let (mood, conf) = (.happy, 0.72)
      

      // 2) Use only user-preferred genres (no seed artists/tracks)
      let genres: [String] = Array(prefs.preferredGenres)

      // 3) Fetch recommendations
      let trackURIs = try await music.recommendTrackURIs(
        for: mood,
        preferredGenres: genres,
        limit: 20
      )

      // 4) Create playlist & add tracks
      let playlistName = "EmotionPlay • \(mood.rawValue.capitalized)"
      let (playlistID, externalURL) = try await music.createPlaylist(
        name: playlistName,
        description: "Auto-created from your photo mood: \(mood.rawValue)",
        isPublic: false
      )

      if !trackURIs.isEmpty {
        try await music.addTracks(to: playlistID, uris: trackURIs)
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
      self.detectedMood = mood
      self.confidence = conf
      self.createdPlaylist = Playlist(id: playlistID, name: playlistName, url: externalURL)
      self.isLoading = false

    } catch {
      self.errorMessage = "Failed: \(error.localizedDescription)"
      self.isLoading = false
      print("analyzeAndCreate error:", error)
    }
  }
}
