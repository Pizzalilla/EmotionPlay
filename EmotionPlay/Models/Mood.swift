//
//  Mood.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

public enum Mood: String, CaseIterable, Codable, Identifiable {
  case happy, calm, focused, sad, energetic, nostalgic
  public var id: String { rawValue }
}
