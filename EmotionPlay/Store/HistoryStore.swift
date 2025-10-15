//
//  HistoryStore.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

import Foundation

final class HistoryStore: ObservableObject {
  @Published var items: [HistoryItem] = []

  func add(_ item: HistoryItem) { items.insert(item, at: 0) }
    func rename(id: HistoryItem.ID, to newTitle: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].playlistName = newTitle
    }
  func delete(at offsets: IndexSet) { items.remove(atOffsets: offsets) }
  func clearAll() { items.removeAll() }
}


