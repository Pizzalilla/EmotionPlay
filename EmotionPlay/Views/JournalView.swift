//
//  JournalView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import SwiftUI

struct JournalView: View {
  @ObservedObject var store: JournalStore

  var body: some View {
    NavigationStack {
      List(store.entries) { entry in
        VStack(alignment: .leading, spacing: 4) {
          Text("\(entry.song.title) — \(entry.song.artist)")
            .font(.headline)
          Text("Mood: \(entry.mood.rawValue.capitalized) • \(entry.date.formatted(date: .abbreviated, time: .omitted))")
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .listRowBackground(Color.appSurfaceDark)
      }
      .scrollContentBackground(.hidden)
      .background(Color.appBackground)
      .navigationTitle("Journal")
      .tint(.appTint)
    }
  }
}
