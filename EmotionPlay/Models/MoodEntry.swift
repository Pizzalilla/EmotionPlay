//
//  MoodEntry.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

struct MoodEntry: Identifiable, Codable {
  var id = UUID()
  var date: Date
  var mood: Mood
  var note: String?

  init(id: UUID = UUID(), date: Date, mood: Mood, note: String? = nil) {
    self.id = id
    self.date = date
    self.mood = mood
    self.note = note
  }
}

