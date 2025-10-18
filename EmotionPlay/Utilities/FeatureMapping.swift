//
//  FeatureMapping.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

struct RecFeatures {
  let valence: ClosedRange<Double>
  let energy: ClosedRange<Double>
  let danceability: ClosedRange<Double>
  let tempo: ClosedRange<Double>
}

func features(for mood: Mood) -> RecFeatures {
  switch mood {
  case .happy:
    return .init(valence: 0.7...1.0, energy: 0.6...0.9, danceability: 0.6...0.9, tempo: 105...135)
  case .energetic:
    return .init(valence: 0.5...0.9, energy: 0.8...1.0, danceability: 0.6...0.9, tempo: 120...155)
  case .calm:
    return .init(valence: 0.5...0.9, energy: 0.1...0.35, danceability: 0.3...0.6, tempo: 60...90)
  case .sad:
    return .init(valence: 0.0...0.35, energy: 0.1...0.4, danceability: 0.2...0.5, tempo: 60...90)
  case .anxious:
    return .init(valence: 0.1...0.45, energy: 0.6...0.9, danceability: 0.4...0.7, tempo: 110...140)
  case .angry:
    return .init(valence: 0.1...0.4, energy: 0.8...1.0, danceability: 0.4...0.7, tempo: 120...160)
  case .melancholic:
    return .init(valence: 0.2...0.5, energy: 0.2...0.5, danceability: 0.3...0.6, tempo: 65...95)
  case .focused:     // NEW: low valence, mid-low energy, steady tempos
    return .init(valence: 0.45...0.75, energy: 0.25...0.55, danceability: 0.35...0.65, tempo: 80...110)
  case .nostalgic:   // NEW: warm valence, moderate energy, mid tempos
    return .init(valence: 0.55...0.85, energy: 0.35...0.65, danceability: 0.4...0.7, tempo: 85...115)
  }
}

