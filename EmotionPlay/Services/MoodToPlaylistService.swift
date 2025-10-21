import Foundation

final class MoodToPlaylistService {
    private let recco: ReccoBeatsClient
    private let spotify: SpotifyPlaylistService

    private let moodSeeds: [String: [String]] = [
        "happy":    ["3AJwUDP919kvQ9QcozQPxg","6habFhsOp2NvshLv26DqMb"],
        "sad":      ["4iJyoBOLtHqaGxP12qzhQI","3ZCTVFBt2Brf31RLEnCkWJ"],
        "angry":    ["0eGsygTp906u18L0Oimnem","2EqlS6tkEnglzr7tkKAAYD"],
        "energetic":["0VjIjW4GlUZAMYd2vXMi3b","7ytR5pFWmSjzHJIeQkgog4"]
    ]

    init(recco: ReccoBeatsClient, spotify: SpotifyPlaylistService) {
        self.recco = recco
        self.spotify = spotify
    }

    func createPlaylist(for mood: String) async throws -> String {
        let key = mood.lowercased()
        let seeds = moodSeeds[key] ?? []
        guard !seeds.isEmpty else {
            throw NSError(domain: "ReccoBeats", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "No seeds configured for mood '\(mood)'."])
        }

        // 1) Get recs (includes href in each item)
        let recs = try await recco.getRecommendations(seeds: seeds, size: 20)

        // 2) Build Spotify URIs, using href when present; fetch detail only if needed
        var uris: [String] = []
        uris.reserveCapacity(recs.count)

        for item in recs {
            if let uri = recco.spotifyURI(fromHref: item.href) {
                uris.append(uri)
            } else {
                // Fallback: get detail → href
                let detail = try await recco.getTrackDetail(id: item.id)
                if let uri = recco.spotifyURI(fromHref: detail.href) {
                    uris.append(uri)
                }
            }
        }

        // 3) Create playlist and add tracks
        let playlistName = "EmotiPlay – \(key.capitalized)"
        let playlistId = try await spotify.createPlaylist(named: playlistName, isPublic: false)
        try await spotify.addTracks(uris, to: playlistId)
        return playlistId
    }
}
