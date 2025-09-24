
import Foundation

public protocol PlaylistCreator {
  func createPlaylist(name: String, description: String?, isPublic: Bool)
  async throws -> (id: String, url: URL?)
  func addTracks(to playlistID: String, uris: [String]) async throws
}
