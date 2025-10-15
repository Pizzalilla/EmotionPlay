//
//  ContentView.swift
//  EmotionPlay
//

import SwiftUI
import UIKit

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
        disconnectAction: { /* optionally clear tokens, etc. */ },
        clearHistoryAction: { history.clearAll() },
        isConnected: homeVM.isAuthorized
      )
      .tabItem { Label("Profile", systemImage: "person.fill") }
      .tag(2)
    }
    .tint(Color.appTint)
    .background(Color.appBackground.ignoresSafeArea())

    // Minimal presenter that hands a UIViewController to start ASWebAuthenticationSession
    .sheet(isPresented: $showAuthSheet) {
      AuthSheetForProfile { vc in
        Task { await homeVM.connectSpotify(from: vc) }
      }
    }
  }
}

// MARK: - Auth presenter used by Profile tab
private struct AuthSheetForProfile: UIViewControllerRepresentable {
  let connect: (UIViewController) -> Void

  func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    // Fire once when the sheet appears
    if !context.coordinator.didStart {
      context.coordinator.didStart = true
      connect(uiViewController)
    }
  }

  func makeCoordinator() -> Coordinator { Coordinator() }

  final class Coordinator {
    var didStart = false
  }
}
