//
//  ContentView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var auth = SpotifyAuthManager()
  @StateObject private var journal = JournalStore()

  var body: some View {
    let client = SpotifyAPIClient(auth: auth)
    let vm = RecommendViewModel(musicClient: client, journal: journal)

    TabView {
      RecommendView(vm: vm)
        .tabItem { Label("Recommend", systemImage: "music.note.list") }

      JournalView(store: journal)
        .tabItem { Label("Journal", systemImage: "book") }

      SettingsView()
        .tabItem { Label("Settings", systemImage: "gearshape") }
    }
    .tint(.appTint)
    .background(Color.appBackground.ignoresSafeArea())
  }
}

#Preview {
    ContentView()
}
