import Foundation
import OSLog

private let logger = Logger(subsystem: "com.emotionplay.spotify", category: "Playlist")

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
        
        logger.info("📡 Fetching user ID from Spotify...")
        let (data, response) = try await URLSession.shared.data(for: req)
        
        // ✅ Check HTTP status code
        guard let http = response as? HTTPURLResponse else {
            throw PlaylistError.networkError("Invalid response")
        }
        
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("❌ Failed to get user ID: HTTP \(http.statusCode)")
            logger.error("Response: \(body)")
            throw PlaylistError.spotifyError(http.statusCode, body)
        }
        
        // ✅ Try to decode with better error handling
        do {
            let me = try JSONDecoder().decode(SpotifyUser.self, from: data)
            cachedUserID = me.id
            logger.info("✅ Got user ID: \(me.id)")
            return me.id
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("❌ Failed to decode user: \(error.localizedDescription)")
            logger.error("Response body: \(body)")
            throw PlaylistError.decodingError("User", body)
        }
    }

    func createPlaylist(named name: String, isPublic: Bool = false) async throws -> String {
        let userId = try await userID()
        
        var req = URLRequest(url: base.appendingPathComponent("users/\(userId)/playlists"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PlaylistCreateRequest(name: name, isPublic: isPublic)
        req.httpBody = try JSONEncoder().encode(body)

        logger.info("🎵 Creating playlist: '\(name)'")
        let (data, response) = try await URLSession.shared.data(for: req)
        
        // ✅ Check HTTP status code
        guard let http = response as? HTTPURLResponse else {
            throw PlaylistError.networkError("Invalid response")
        }
        
        // Spotify returns 201 Created for successful playlist creation
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("❌ Failed to create playlist: HTTP \(http.statusCode)")
            logger.error("Response: \(body)")
            throw PlaylistError.spotifyError(http.statusCode, body)
        }
        
        // ✅ Try to decode with better error handling
        do {
            let playlist = try JSONDecoder().decode(SpotifyPlaylist.self, from: data)
            logger.info("✅ Created playlist: \(playlist.id)")
            return playlist.id
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("❌ Failed to decode playlist: \(error.localizedDescription)")
            logger.error("Response body: \(body)")
            throw PlaylistError.decodingError("Playlist", body)
        }
    }

    func addTracks(_ uris: [String], to playlistId: String) async throws {
        guard !uris.isEmpty else { return }
        
        var req = URLRequest(url: base.appendingPathComponent("playlists/\(playlistId)/tracks"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["uris": uris]
        req.httpBody = try JSONEncoder().encode(body)
        
        logger.info("➕ Adding \(uris.count) tracks to playlist \(playlistId)")
        let (data, response) = try await URLSession.shared.data(for: req)
        
        // ✅ Check HTTP status code
        guard let http = response as? HTTPURLResponse else {
            throw PlaylistError.networkError("Invalid response")
        }
        
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            logger.error("❌ Failed to add tracks: HTTP \(http.statusCode)")
            logger.error("Response: \(body)")
            throw PlaylistError.spotifyError(http.statusCode, body)
        }
        
        logger.info("✅ Successfully added tracks to playlist")
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

// MARK: - Error Types
enum PlaylistError: Error, LocalizedError {
    case networkError(String)
    case spotifyError(Int, String)
    case decodingError(String, String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .spotifyError(let code, let body):
            return "Spotify API error (\(code)): \(body.prefix(200))"
        case .decodingError(let type, let body):
            return "Failed to decode \(type): \(body.prefix(200))"
        }
    }
}
