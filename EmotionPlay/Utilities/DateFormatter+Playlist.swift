//
//  DateFormatter+Playlist.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import Foundation

extension DateFormatter {
  static let playlistDate: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "d MMM"
    return df
  }()
}
