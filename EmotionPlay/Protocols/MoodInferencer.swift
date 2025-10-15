//
//  MoodInferencer.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

// Protocols/MoodInferencer.swift
import Foundation

/// Returns (mood, confidence 0…1) for an input image.
protocol MoodInferencer {
  func infer(fromImageData data: Data) async throws -> (Mood, Double)
}



