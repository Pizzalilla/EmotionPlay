//
//  HistoryView.swift
//  EmotionPlay
//
//  Updated with consistent background styling
//

import SwiftUI

struct HistoryView: View {
  @ObservedObject var store: HistoryStore

  @State private var renamingItem: HistoryItem? = nil
  @State private var renameText: String = ""

  var body: some View {
    NavigationStack {
      ZStack {
        // Consistent background with HomeView
        Color.AppBackground.ignoresSafeArea()
        
        if store.items.isEmpty {
          // Empty state
          VStack(spacing: 20) {
            Image(systemName: "music.note.list")
              .font(.system(size: 60))
              .foregroundColor(.gray.opacity(0.5))
            
            Text("No Playlists Yet")
              .font(.title2.bold())
              .foregroundColor(.white)
            
            Text("Create your first mood-based playlist on the Home tab")
              .font(.subheadline)
              .foregroundColor(.gray)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
          }
        } else {
          List {
            ForEach(store.items) { item in
              HistoryRow(item: item)
                .listRowBackground(Color.cardBackground)
                .listRowSeparatorTint(Color.gray.opacity(0.3))
                .contextMenu {
                  Button("Rename") {
                    renamingItem = item
                    renameText = item.title
                  }
                }
            }
            .onDelete(perform: store.delete)
          }
          .scrollContentBackground(.hidden)
          .listStyle(.plain)
        }
      }
      .navigationTitle("Your Playlists")
      .toolbar {
        if !store.items.isEmpty {
          EditButton()
            .foregroundColor(.AppGreenAccent)
        }
      }
      .sheet(item: $renamingItem) { item in
        RenameSheet(
          title: $renameText,
          onCancel: { renamingItem = nil },
          onSave: {
            store.rename(id: item.id, to: renameText.trimmingCharacters(in: .whitespacesAndNewlines))
            renamingItem = nil
          }
        )
      }
    }
  }
}

// MARK: - Row

private struct HistoryRow: View {
  let item: HistoryItem

  var body: some View {
    HStack(spacing: 16) {
      // Thumbnail
      if let img = item.uiImage {
        Image(uiImage: img)
          .resizable()
          .scaledToFill()
          .frame(width: 64, height: 64)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(Color.gray.opacity(0.3), lineWidth: 1)
          )
      } else {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(
            LinearGradient(
              colors: [Color.AppGreenAccent.opacity(0.6), Color.AppGreen3.opacity(0.6)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 64, height: 64)
          .overlay(
            Image(systemName: "music.note")
              .font(.title2)
              .foregroundColor(.white)
          )
      }

      // Info
      VStack(alignment: .leading, spacing: 6) {
        // Date
        Text(item.date.formatted(date: .abbreviated, time: .shortened))
          .font(.caption)
          .foregroundColor(.gray)

        // Mood + Confidence
        HStack(spacing: 6) {
          Text(moodEmoji(item.mood))
            .font(.body)
          
          Text(item.mood.rawValue.capitalized)
            .font(.headline)
            .foregroundColor(.white)
          
          if let conf = item.confidence {
            Text("\(Int(conf * 100))%")
              .font(.caption)
              .foregroundColor(.AppGreenAccent)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.AppGreenAccent.opacity(0.2))
              .cornerRadius(6)
          }
        }
        
        // Playlist name
        Text(item.playlistName)
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.7))
          .lineLimit(1)
      }

      Spacer()

      // Play button
      if let url = item.playlistURL {
        Link(destination: url) {
          Image(systemName: "play.circle.fill")
            .font(.system(size: 32))
            .foregroundColor(.AppGreenAccent)
        }
      }
    }
    .padding(.vertical, 8)
  }
  
  private func moodEmoji(_ mood: Mood) -> String {
    switch mood {
    case .happy: return "😊"
    case .sad: return "😢"
    case .calm: return "😌"
    case .energetic: return "⚡️"
    case .angry: return "😠"
    case .anxious: return "😰"
    case .melancholic: return "😔"
    case .focused: return "🎯"
    case .nostalgic: return "🌅"
    }
  }
}

// MARK: - Rename Sheet

private struct RenameSheet: View {
  @Binding var title: String
  let onCancel: () -> Void
  let onSave: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ZStack {
        Color.AppBackground.ignoresSafeArea()
        
        Form {
          Section {
            TextField("e.g. Morning Boost, Exam Stress Mix", text: $title)
              .textFieldStyle(.plain)
              .foregroundColor(.white)
          } header: {
            Text("Session Title")
              .foregroundColor(.gray)
          }
          .listRowBackground(Color.cardBackground)
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("Rename")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
            onCancel()
          }
          .foregroundColor(.gray)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            dismiss()
            onSave()
          }
          .foregroundColor(.AppGreenAccent)
          .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}
