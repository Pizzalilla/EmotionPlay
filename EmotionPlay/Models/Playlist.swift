//
//  Playlist.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

struct Playlist: Identifiable, Codable, Hashable {
  let id: String
  let name: String
  let url: URL?
  let coverURL: URL?   // optional artwork URL

  init(id: String, name: String, url: URL?, coverURL: URL? = nil) {
    self.id = id
    self.name = name
    self.url = url
    self.coverURL = coverURL
  }
}
