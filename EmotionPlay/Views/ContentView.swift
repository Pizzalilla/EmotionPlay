//
//  ContentView.swift
//  EmotionPlay
//

import SwiftUI

struct ContentView: View {
  // Stores / state
  @StateObject private var auth    = SpotifyAuthManager()
  @StateObject private var history = HistoryStore()
  @StateObject private var prefs   = UserPreferences()

  // UI state
  @State private var selectedTab   = 0
  @State private var showAuthSheet = false

  var body: some View {
    // Services
    let client = SpotifyAPIClient(auth: auth)
    let infer = RemoteMoodInferencer(apiKey: "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") // <- paste hf_... here

    // VM (inject shared stores/services)
    let homeVM = HomeViewModel(
      inferencer: infer,
      music: client,
      prefs: prefs,
      history: history
    )

    TabView(selection: $selectedTab) {
      // HOME
      HomeView(vm: homeVM, goToProfileConnect: { selectedTab = 2 })
        .tabItem { Label("Home", systemImage: "house.fill") }
        .tag(0)

      // HISTORY
      HistoryView(store: history)
        .tabItem { Label("History", systemImage: "clock.fill") }
        .tag(1)

      // PROFILE (Spotify connect only here)
      ProfileView(
        prefs: prefs,
        connectAction: { showAuthSheet = true },
        disconnectAction: {
          auth.disconnect()
          homeVM.isAuthorized = false
          prefs.spotifyUsername = nil
        },
        clearHistoryAction: { history.clearAll() },
        isConnected: homeVM.isAuthorized
      )
      .tabItem { Label("Profile", systemImage: "person.fill") }
      .tag(2)
    }
    .tint(Color.appTint)
    .background(Color.green)

    // Handle Spotify auth - no need for sheet, just trigger directly
    .onChange(of: showAuthSheet) { newValue in
      if newValue {
        Task {
            await homeVM.connectSpotify(from: UIViewController.init() )
          showAuthSheet = false
        }
      }
    }
  }
}


