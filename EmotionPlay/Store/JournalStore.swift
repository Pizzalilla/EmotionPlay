//
//  JournalStore.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

final class JournalStore: ObservableObject {
  @Published var entries: [MoodEntry] = [
    .init(date: Date().addingTimeInterval(-86400),   mood: .happy,    song: .init(title: "Blinding Lights", artist: "The Weeknd"), notes: nil),
    .init(date: Date().addingTimeInterval(-172800),  mood: .focused,  song: .init(title: "Time",            artist: "Hans Zimmer"), notes: nil),
    .init(date: Date().addingTimeInterval(-259200),  mood: .energetic, song: .init(title: "Stronger",        artist: "Kanye West"), notes: nil)
  ]

  func recentSeedArtists(limit: Int = 5) -> [String] {
    Array(Set(entries.suffix(10).map { $0.song.artist })).prefix(limit).map { $0 }
  }
  func recentSeedTracks(limit: Int = 5) -> [String] {
    entries.suffix(10).map { "\($0.song.title) – \($0.song.artist)" }.prefix(limit).map { $0 }
  }
}
