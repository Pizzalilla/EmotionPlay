//
//  FeatureMapping.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

struct SpotifyFeatureTargets {
  let valence: ClosedRange<Double>
  let energy: ClosedRange<Double>
  let danceability: ClosedRange<Double>
  let acousticness: ClosedRange<Double>
  let tempo: ClosedRange<Int>
}

func features(for mood: Mood) -> SpotifyFeatureTargets {
  switch mood {
  case .happy:     return .init(valence: 0.7...0.9, energy: 0.6...0.8,  danceability: 0.6...0.85, acousticness: 0.0...0.3, tempo: 110...135)
  case .calm:      return .init(valence: 0.4...0.7, energy: 0.2...0.45, danceability: 0.3...0.6,  acousticness: 0.4...1.0, tempo:  60...100)
  case .focused:   return .init(valence: 0.4...0.6, energy: 0.3...0.55, danceability: 0.4...0.6,  acousticness: 0.2...0.7, tempo:  70...110)
  case .sad:       return .init(valence: 0.1...0.35,energy: 0.2...0.5,  danceability: 0.2...0.5,  acousticness: 0.3...1.0, tempo:  60...100)
  case .energetic: return .init(valence: 0.6...0.8, energy: 0.75...0.95,danceability: 0.6...0.9,  acousticness: 0.0...0.3, tempo: 120...150)
  case .nostalgic: return .init(valence: 0.5...0.7, energy: 0.4...0.6,  danceability: 0.4...0.7,  acousticness: 0.2...0.8, tempo:  80...120)
  }
}
