//
//  ContentView.swift
//  EmotionPlay
//
//  Updated with auto-redirect to History after playlist creation
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
  @State private var initError: String?

  var body: some View {
    // Services
    let client = SpotifyAPIClient(auth: auth)
    
    // Use Direct Core ML inferencer
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
          spotifyAuth: auth,
          prefs: prefs,
          history: history
        )

        TabView(selection: $selectedTab) {
          // HOME
          HomeView(
            vm: homeVM,
            goToProfileConnect: { selectedTab = 2 },
            onPlaylistCreated: { selectedTab = 1 }  // ✨ NEW: Redirect to History
          )
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

          // HISTORY
          HistoryView(store: history)
            .tabItem { Label("Playlists", systemImage: "music.note.list") }
            .tag(1)

          // PROFILE
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
        .tint(Color.AppTint)
        .onChange(of: showAuthSheet) { newValue in
          if newValue {
            Task {
              await homeVM.connectSpotify(from: UIViewController.init())
              showAuthSheet = false
            }
          }
        }
      } else {
        // Error state
        ZStack {
          Color.AppBackground.ignoresSafeArea()
          
          VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 60))
              .foregroundColor(.red)
            
            Text("Setup Required")
              .font(.title.bold())
              .foregroundColor(.white)
            
            Text(initError ?? "Could not initialize mood detection")
              .multilineTextAlignment(.center)
              .foregroundColor(.gray)
              .padding(.horizontal)
            
            Text("Please ensure your Core ML model is properly added to the project")
              .font(.caption)
              .foregroundColor(.gray)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .padding()
        }
      }
    }
  }
}
