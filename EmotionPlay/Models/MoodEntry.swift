//
//  MoodEntry.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

public struct MoodEntry: Codable, Hashable, Identifiable {
  public let id: UUID = .init()
  public var date: Date
  public var mood: Mood
  public var song: Song
  public var notes: String?
}
