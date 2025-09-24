//
//  RecommendViewModel.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation
import UIKit

@MainActor
final class RecommendViewModel: ObservableObject {
  @Published var selectedMood: Mood = .happy
  @Published var trackCount: Int = 20
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil
  @Published var createdPlaylist: Playlist? = nil

  private let musicClient: MusicProviderClient
  private let journal: JournalStore

  init(musicClient: MusicProviderClient, journal: JournalStore) {
    self.musicClient = musicClient
    self.journal = journal
  }

  var isAuthorized: Bool { musicClient.isAuthorized }

  func connectSpotify(from vc: UIViewController) async {
    do { try await musicClient.authorize(from: vc); errorMessage = nil }
    catch { errorMessage = "Spotify login failed. Please try again." }
  }

  func createMoodMix() async {
    isLoading = true; errorMessage = nil; createdPlaylist = nil
    do {
      let seedsA = journal.recentSeedArtists()
      let seedsT = journal.recentSeedTracks()
      let uris = try await musicClient.recommendTrackURIs(
        for: selectedMood, seedArtists: seedsA, seedTracks: seedsT, limit: trackCount
      )
      guard !uris.isEmpty else { throw URLError(.cannotCreateFile) }

      let title = "Emotion Play – \(selectedMood.rawValue.capitalized) \(DateFormatter.playlistDate.string(from: Date()))"
      let desc  = "A personalized mix based on your recent listens and mood."
      let (pid, url) = try await musicClient.createPlaylist(name: title, description: desc, isPublic: false)
      try await musicClient.addTracks(to: pid, uris: uris)
      createdPlaylist = .init(id: pid, name: title, url: url, coverURL: nil)
    }
    catch URLError.cannotLoadFromNetwork { errorMessage = "Rate limited. Please wait a moment and try again." }
    catch URLError.userAuthenticationRequired { errorMessage = "Please connect Spotify to create a playlist." }
    catch { errorMessage = "Couldn’t create your mix. Please try again." }
    isLoading = false
  }
}
