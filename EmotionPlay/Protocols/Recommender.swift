
import Foundation

public protocol Recommender {
  func recommendTrackURIs(
    for mood: Mood,
    seedArtists: [String],
    seedTracks: [String],
    limit: Int
  ) async throws -> [String]
}
