//
//  SettingView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import SwiftUI

struct SettingsView: View {
  var body: some View {
    NavigationStack {
      Form {
        Section("Theme") {
          HStack {
            Circle().fill(Color.appGreen1).frame(width: 18, height: 18)
            Circle().fill(Color.appGreen2).frame(width: 18, height: 18)
            Circle().fill(Color.appGreen3).frame(width: 18, height: 18)
            Circle().fill(Color.appGreen4).frame(width: 18, height: 18)
            Circle().fill(Color.appGreenAccent).frame(width: 18, height: 18)
          }
        }
        Section("About") {
          Text("Emotion Play – v0.1")
          Text("Mode B: Spotify playlist creation")
        }
        Section("Privacy") {
          Text("Photo-based mood detection will run on-device in a future version.")
        }
      }
      .navigationTitle("Settings")
    }
  }
}
