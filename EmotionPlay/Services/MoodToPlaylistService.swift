import Foundation

final class MoodToPlaylistService {
    private let recco: ReccoBeatsClient
    private let spotify: SpotifyPlaylistService

    init(recco: ReccoBeatsClient, spotify: SpotifyPlaylistService) {
        self.recco = recco
        self.spotify = spotify
    }

    /// Full flow: get recs from ReccoBeats → extract Spotify URIs → add to playlist
    func createPlaylist(for mood: String) async throws -> String {
        // 1. Fetch ReccoBeats recs
        let recIds = try await recco.getRecommendations(seeds: [mood], size: 20)

        // 2. Resolve Spotify URIs
        var uris: [String] = []
        for id in recIds {
            let detail = try await recco.getTrackDetail(id: id)
            if let uri = recco.spotifyURI(from: detail) {
                uris.append(uri)
            }
        }

        // 3. Create Spotify playlist
        let playlistId = try await spotify.createPlaylist(named: "EmotiPlay – \(mood.capitalized)", isPublic: false)

        // 4. Add tracks to playlist
        try await spotify.addTracks(uris, to: playlistId)

        return playlistId
    }
}
