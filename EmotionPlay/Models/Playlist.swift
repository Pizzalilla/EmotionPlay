//
//  Playlist.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

public struct Playlist: Identifiable, Hashable {
  public let id: String
  public let name: String
  public let url: URL?
  public let coverURL: URL?
}
