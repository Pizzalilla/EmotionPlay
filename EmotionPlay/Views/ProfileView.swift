//
//  ProfileView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

import SwiftUI

struct ProfileView: View {
  @ObservedObject var prefs: UserPreferences
  let connectAction: () -> Void
  let disconnectAction: () -> Void
  let clearHistoryAction: () -> Void
  let isConnected: Bool

  private let allGenres = ["pop","hip-hop","rock","edm","lo-fi","jazz","indie","r&b"]
  private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          SectionHeader(title: "Spotify Connection")

          ConnectionCard(isConnected: isConnected,
                         username: prefs.spotifyUsername,
                         connect: connectAction,
                         disconnect: disconnectAction)

          SectionHeader(title: "Preferred Genres")

          LazyVGrid(columns: columns, spacing: 10) {
            ForEach(allGenres, id: \.self) { tag in
              GenreChip(tag: tag, isOn: prefs.preferredGenres.contains(tag)) {
                if prefs.preferredGenres.contains(tag) {
                  prefs.preferredGenres.remove(tag)
                } else {
                  prefs.preferredGenres.insert(tag)
                }
              }
            }
          }

          SectionHeader(title: "Settings")
          Button("Clear All History", role: .destructive, action: clearHistoryAction)
        }
        .padding()
      }
      .background(Color.appBackground.ignoresSafeArea())
      .foregroundStyle(.white)
      .navigationTitle("Profile")
    }
  }
}

private struct SectionHeader: View {
  let title: String
  var body: some View {
    Text(title)
      .font(.title).bold()
      .foregroundStyle(Color.appGreenAccent)
  }
}

private struct ConnectionCard: View {
  let isConnected: Bool
  let username: String?
  let connect: () -> Void
  let disconnect: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle")
          .foregroundStyle(isConnected ? .green : .red)
        Text(isConnected ? "Connected\(username != nil ? " as @\(username!)" : "")" : "Not Connected")
        Spacer()
      }
      HStack {
        if isConnected {
          Button("Disconnect", action: disconnect)
            .buttonStyle(.borderedProminent).tint(.pink)
        } else {
          Button("Connect Spotify", action: connect)
            .buttonStyle(.borderedProminent).tint(Color.appGreen3)
        }
      }
    }
    .padding()
    .background(RoundedRectangle(cornerRadius: 16).fill(Color.appSurfaceDark))
  }
}

private struct GenreChip: View {
  let tag: String
  let isOn: Bool
  let toggle: () -> Void

  var body: some View {
    Text(tag.capitalized)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 18)
          .fill(isOn ? Color.appGreen2.opacity(0.35) : Color.appSurfaceDark)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(isOn ? Color.appGreenAccent : .gray.opacity(0.4))
      )
      .onTapGesture(perform: toggle)
  }
}
