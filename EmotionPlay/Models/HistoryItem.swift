//
//  HistoryItem.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 3/10/2025.
//

// Models/HistoryItem.swift
import Foundation
import UIKit

struct HistoryItem: Identifiable, Codable, Hashable {
  let id: UUID
  let date: Date
  let mood: Mood
  var playlistName: String
  let imageData: Data
  let playlistURL: URL?
  let coverURL: URL?      // optional artwork URL
  let confidence: Double? // 0…1 (optional so older entries still decode)

  init(
    id: UUID = UUID(),
    date: Date,
    mood: Mood,
    playlistName: String,
    imageData: Data,
    playlistURL: URL?,
    coverURL: URL? = nil,
    confidence: Double? = nil
  ) {
    self.id = id
    self.date = date
    self.mood = mood
    self.playlistName = playlistName
    self.imageData = imageData
    self.playlistURL = playlistURL
    self.coverURL = coverURL
    self.confidence = confidence
  }

  // Convenience for thumbnails in SwiftUI
  var uiImage: UIImage? { UIImage(data: imageData) }

  // Title used in the History row if you want a display name
  var title: String {
    playlistName
  }
}

