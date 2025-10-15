//
//  Mood.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

/// Primary mood inferred from the photo.
enum Mood: String, Codable, CaseIterable {
  case happy
  case calm
  case sad
  case energetic
  case anxious
  case angry
  case melancholic
  case focused        // NEW
  case nostalgic      // NEW
}

