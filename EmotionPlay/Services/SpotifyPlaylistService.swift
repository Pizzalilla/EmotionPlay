import Foundation

protocol SpotifyPlaylisting {
    func createPlaylist(named name: String, isPublic: Bool) async throws -> String
    func addTracks(_ uris: [String], to playlistId: String) async throws
}

final class SpotifyPlaylistService: SpotifyPlaylisting {
    private let tokenProvider: SpotifyAuthProviding
    private let base = URL(string: "https://api.spotify.com/v1")!
    private var cachedUserID: String?

    init(tokenProvider: SpotifyAuthProviding) {
        self.tokenProvider = tokenProvider
    }

    private func token() throws -> String {
        try tokenProvider.validTokenOrThrow()
    }

    private func userID() async throws -> String {
        if let cachedUserID { return cachedUserID }
        var req = URLRequest(url: base.appendingPathComponent("me"))
        req.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        let me = try JSONDecoder().decode(SpotifyUser.self, from: data)
        cachedUserID = me.id
        return me.id
    }

    func createPlaylist(named name: String, isPublic: Bool = false) async throws -> String {
        let userId = try await userID()
        var req = URLRequest(url: base.appendingPathComponent("users/\(userId)/playlists"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PlaylistCreateRequest(name: name, isPublic: isPublic)
        req.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: req)
        let playlist = try JSONDecoder().decode(SpotifyPlaylist.self, from: data)
        return playlist.id
    }

    func addTracks(_ uris: [String], to playlistId: String) async throws {
        guard !uris.isEmpty else { return }
        var req = URLRequest(url: base.appendingPathComponent("playlists/\(playlistId)/tracks"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["uris": uris]
        req.httpBody = try JSONEncoder().encode(body)
        _ = try await URLSession.shared.data(for: req)
    }
}

// MARK: - Supporting Models
struct SpotifyUser: Decodable {
    let id: String
}

struct SpotifyPlaylist: Decodable {
    let id: String
}

struct PlaylistCreateRequest: Encodable {
    let name: String
    let `public`: Bool

    init(name: String, isPublic: Bool) {
        self.name = name
        self.public = isPublic
    }
}
