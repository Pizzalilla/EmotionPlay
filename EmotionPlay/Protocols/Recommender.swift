import Foundation

/// Music recommendation + playlist ops used by the app.
protocol Recommender {
  func recommendTrackURIs(for mood: Mood, preferredGenres: [String], limit: Int) async throws -> [String]


  func createPlaylist(
    name: String,
    description: String?,
    isPublic: Bool
  ) async throws -> (id: String, url: URL?)

  func addTracks(to playlistID: String, uris: [String]) async throws
}
