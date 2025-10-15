//
//  UserPreferences.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

import Foundation

final class UserPreferences: ObservableObject {
  @Published var preferredGenres: Set<String> = ["pop","hip-hop","rock"]
  @Published var spotifyUsername: String? = nil
}
