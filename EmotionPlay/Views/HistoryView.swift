//
//  HistoryView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

import SwiftUI

struct HistoryView: View {
  @ObservedObject var store: HistoryStore

  @State private var renamingItem: HistoryItem? = nil
  @State private var renameText: String = ""

  var body: some View {
    NavigationStack {
      List {
        ForEach(store.items) { item in
          HistoryRow(item: item)
            .listRowBackground(Color.appSurfaceDark)
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
      .background(Color.appBackground)
      .navigationTitle("Your History")
      .toolbar { EditButton() }
      .sheet(item: $renamingItem) { item in
        RenameSheet(title: $renameText,
                    onCancel: { renamingItem = nil },
                    onSave: {
                      store.rename(id: item.id, to: renameText.trimmingCharacters(in: .whitespacesAndNewlines))
                      renamingItem = nil
                    })
      }
    }
  }
}

// MARK: - Row

private struct HistoryRow: View {
  let item: HistoryItem

  var body: some View {
    HStack(spacing: 12) {
      if let img = item.uiImage {
        Image(uiImage: img)
          .resizable().scaledToFill()
          .frame(width: 54, height: 54)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      } else {
        RoundedRectangle(cornerRadius: 12)
          .fill(LinearGradient(colors: [.purple, .cyan],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
          .frame(width: 54, height: 54)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(item.date.formatted(date: .abbreviated, time: .shortened))
          .font(.caption)
          .foregroundStyle(.secondary)

          Text(
            item.title.isEmpty
              ? "\(item.mood.rawValue.capitalized)\(item.confidence.map { " \(Int($0 * 100))%" } ?? "")"
              : item.title
          )
          .font(.headline)
          .foregroundStyle(Color.appGreenAccent)
          
          Text(item.playlistName)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.85))

          Spacer()
      }

      Spacer()

        if let url = item.playlistURL {
          Link(destination: url) {
            Image(systemName: "play.circle.fill").font(.title2)
          }
        }
    }
  }
}

// MARK: - Rename Sheet

private struct RenameSheet: View {
  @Binding var title: String
  let onCancel: () -> Void
  let onSave: () -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section("Session Title") {
          TextField("e.g. Morning Boost, Exam Stress Mix", text: $title)
        }
      }
      .navigationTitle("Rename")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save", action: onSave)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}
