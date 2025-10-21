//
//  ProfileView.swift
//  EmotionPlay
//
//  Updated with consistent background styling
//

import SwiftUI

struct ProfileView: View {
  @ObservedObject var prefs: UserPreferences
  let connectAction: () -> Void
  let disconnectAction: () -> Void
  let clearHistoryAction: () -> Void
  let isConnected: Bool

  private let allGenres = ["pop","hip-hop","rock","edm","lo-fi","jazz","indie","r&b"]
  private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

  var body: some View {
    NavigationStack {
      ZStack {
        // Consistent background
        Color.AppBackground.ignoresSafeArea()
        
        ScrollView {
          VStack(alignment: .leading, spacing: 32) {
            // Profile Header
            VStack(spacing: 16) {
              // Profile icon
              ZStack {
                Circle()
                  .fill(
                    LinearGradient(
                      colors: [Color.AppGreenAccent, Color.AppGreen3],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    )
                  )
                  .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                  .font(.system(size: 36, weight: .bold))
                  .foregroundColor(.white)
              }
              .shadow(color: Color.AppGreenAccent.opacity(0.3), radius: 15, x: 0, y: 8)
              
              Text("Your Profile")
                .font(.title2.bold())
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            
            // Spotify Connection
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: "Spotify Connection")
              ConnectionCard(
                isConnected: isConnected,
                username: prefs.spotifyUsername,
                connect: connectAction,
                disconnect: disconnectAction
              )
            }

            // Preferred Genres
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: "Preferred Genres")
              
              Text("Select genres you love for personalized playlists")
                .font(.subheadline)
                .foregroundColor(.gray)
              
              LazyVGrid(columns: columns, spacing: 12) {
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
            }

            // Settings
            VStack(alignment: .leading, spacing: 16) {
              SectionHeader(title: "Settings")
              
              Button(action: clearHistoryAction) {
                HStack {
                  Image(systemName: "trash")
                    .font(.title3)
                  
                  VStack(alignment: .leading, spacing: 4) {
                    Text("Clear All History")
                      .font(.headline)
                    Text("Remove all saved playlists")
                      .font(.caption)
                      .foregroundColor(.gray)
                  }
                  
                  Spacer()
                  
                  Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
              }
            }
            
            // App Info
            VStack(spacing: 8) {
              Text("EmotionPlay")
                .font(.caption)
                .foregroundColor(.gray)
              
              Text("Version 1.0.0")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 40)
          }
          .padding()
        }
      }
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private struct SectionHeader: View {
  let title: String
  var body: some View {
    Text(title)
      .font(.title3.bold())
      .foregroundColor(.white)
  }
}

private struct ConnectionCard: View {
  let isConnected: Bool
  let username: String?
  let connect: () -> Void
  let disconnect: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      // Status
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
            .frame(width: 40, height: 40)
          
          Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.title3)
            .foregroundColor(isConnected ? .green : .red)
        }
        
        VStack(alignment: .leading, spacing: 4) {
          Text(isConnected ? "Connected" : "Not Connected")
            .font(.headline)
            .foregroundColor(.white)
          
          if let username = username {
            Text("@\(username)")
              .font(.subheadline)
              .foregroundColor(.gray)
          } else {
            Text(isConnected ? "Spotify account linked" : "Connect to create playlists")
              .font(.subheadline)
              .foregroundColor(.gray)
          }
        }
        
        Spacer()
      }
      
      // Action button
      if isConnected {
        Button(action: disconnect) {
          HStack {
            Image(systemName: "link.slash")
            Text("Disconnect")
              .font(.system(size: 16, weight: .semibold))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color.red.opacity(0.8))
          .cornerRadius(12)
        }
      } else {
        Button(action: connect) {
          HStack {
            Image(systemName: "link")
            Text("Connect Spotify")
              .font(.system(size: 16, weight: .semibold))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(
            LinearGradient(
              colors: [Color.AppGreenAccent, Color.AppGreen3],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .cornerRadius(12)
          .shadow(color: Color.AppGreenAccent.opacity(0.3), radius: 10, x: 0, y: 5)
        }
      }
    }
    .padding(20)
    .background(Color.cardBackground)
    .cornerRadius(20)
    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
  }
}

private struct GenreChip: View {
  let tag: String
  let isOn: Bool
  let toggle: () -> Void

  var body: some View {
    Button(action: toggle) {
      Text(tag.capitalized)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(isOn ? .white : .gray)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isOn ? Color.AppGreenAccent.opacity(0.3) : Color.cardBackground)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(isOn ? Color.AppGreenAccent : Color.gray.opacity(0.3), lineWidth: 1.5)
        )
    }
    .buttonStyle(.plain)
  }
}
