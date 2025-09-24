//
//  Song.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

public struct Song: Codable, Hashable, Identifiable {
  public let id: UUID = .init()
  public var title: String
  public var artist: String
}
