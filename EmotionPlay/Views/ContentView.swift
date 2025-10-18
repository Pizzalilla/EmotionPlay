//
//  ContentView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import SwiftUI

struct ContentView: View {
<<<<<<< Updated upstream
  @StateObject private var auth = SpotifyAuthManager()
  @StateObject private var journal = JournalStore()
=======
  // Stores / state
  @StateObject private var auth    = SpotifyAuthManager()
  @StateObject private var history = HistoryStore()
  @StateObject private var prefs   = UserPreferences()

  // UI state
  @State private var selectedTab   = 0
  @State private var showAuthSheet = false
  @State private var initError: String?
>>>>>>> Stashed changes

  var body: some View {
    let client = SpotifyAPIClient(auth: auth)
<<<<<<< Updated upstream
    let vm = RecommendViewModel(musicClient: client, journal: journal)

    TabView {
      RecommendView(vm: vm)
        .tabItem { Label("Recommend", systemImage: "music.note.list") }

      JournalView(store: journal)
        .tabItem { Label("Journal", systemImage: "book") }

      SettingsView()
        .tabItem { Label("Settings", systemImage: "gearshape") }
=======
    
    // Use Direct Core ML inferencer (bypasses Vision framework for better simulator compatibility)
    let infer: MoodInferencer? = {
      do {
        return try DirectCoreMLInferencer()
      } catch {
        DispatchQueue.main.async {
          initError = "Failed to load mood detection model: \(error.localizedDescription)"
        }
        return nil
      }
    }()

    Group {
      if let inferencer = infer {
        // VM (inject shared stores/services)
        let homeVM = HomeViewModel(
          inferencer: inferencer,
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
        .onChange(of: showAuthSheet) { newValue in
          if newValue {
            Task {
              await homeVM.connectSpotify(from: UIViewController.init())
              showAuthSheet = false
            }
          }
        }
      } else {
        // Error state if Core ML model fails to load
        VStack(spacing: 20) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 60))
            .foregroundColor(.red)
          
          Text("Setup Required")
            .font(.title.bold())
          
          Text(initError ?? "Could not initialize mood detection")
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal)
          
          Text("Please ensure your Core ML model is properly added to the project")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .padding()
      }
>>>>>>> Stashed changes
    }
    .tint(.appTint)
    .background(Color.appBackground.ignoresSafeArea())
  }
}
<<<<<<< Updated upstream

#Preview {
    ContentView()
}
=======
>>>>>>> Stashed changes
