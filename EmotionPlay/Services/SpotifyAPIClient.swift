import Foundation
import UIKit


// MARK: - Client
final class SpotifyAPIClient: MusicProviderClient, Recommender {
    private let auth: SpotifyAuthProviding
    private let base = URL(string: "https://api.spotify.com/v1")!
    private var cachedUserID: String?

    init(auth: SpotifyAuthProviding) {
        self.auth = auth
    }

    // MARK: MusicProviderClient

    var isAuthorized: Bool {
        (try? auth.validTokenOrThrow()) != nil
    }

    func authorize(from viewController: UIViewController) async throws {
        // Delegate to the auth manager if it conforms to a protocol with authorize(from:)
        // For now, we assume the SpotifyAuthManager handles this
        // This is a bridge method - actual auth happens in SpotifyAuthManager
        guard let authManager = auth as? SpotifyAuthManager else {
            throw SpotifyError.notAuthenticated
        }
        try await authManager.authorize(from: viewController)
    }

    // MARK: Recommender

    func recommendTrackURIs(
        for mood: Mood,
        preferredGenres: [String],
        limit: Int
    ) async throws -> [String] {
        let token = try auth.validTokenOrThrow()

        let moodGenres = defaultGenres(for: mood)
        let seeds = (preferredGenres.isEmpty ? moodGenres : preferredGenres)
            .map { $0.lowercased() }
            .uniqued()
            .prefix(5)

        guard !seeds.isEmpty else { return [] }

        var comps = URLComponents(url: base.appendingPathComponent("recommendations"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 100))),
            URLQueryItem(name: "seed_genres", value: seeds.joined(separator: ",")),
            URLQueryItem(name: "min_popularity", value: "20")
        ]

        let req = try authorizedRequest(url: try comps.url.unwrapped(), method: "GET", token: token)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp, data)

        let decoded = try JSONDecoder().decode(RecommendationsResponse.self, from: data)
        return decoded.tracks.map { $0.uri }
    }

    func createPlaylist(
        name: String,
        description: String?,
        isPublic: Bool
    ) async throws -> (id: String, url: URL?) {
        let token = try auth.validTokenOrThrow()
        let userID = try await currentUserID(using: token)

        var req = try authorizedRequest(
            url: base.appendingPathComponent("users/\(userID)/playlists"),
            method: "POST",
            token: token
        )
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Body: Encodable { let name: String; let `public`: Bool; let description: String? }
        req.httpBody = try JSONEncoder().encode(Body(name: name, public: isPublic, description: description))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp, data)

        let created = try JSONDecoder().decode(PlaylistCreated.self, from: data)
        let url = created.external_urls?["spotify"].flatMap(URL.init(string:))
        return (created.id, url)
    }

    func addTracks(to playlistID: String, uris: [String]) async throws {
        guard !uris.isEmpty else { return }
        let token = try auth.validTokenOrThrow()

        var req = try authorizedRequest(
            url: base.appendingPathComponent("playlists/\(playlistID)/tracks"),
            method: "POST",
            token: token
        )
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Encodable { let uris: [String] }
        req.httpBody = try JSONEncoder().encode(Body(uris: uris))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp, data)
    }

    // MARK: Helpers

    private func currentUserID(using token: String) async throws -> String {
        if let id = cachedUserID { return id }
        let req = try authorizedRequest(url: base.appendingPathComponent("me"), method: "GET", token: token)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp, data)
        struct Me: Decodable { let id: String }
        let me = try JSONDecoder().decode(Me.self, from: data)
        cachedUserID = me.id
        return me.id
    }

    private func authorizedRequest(url: URL, method: String, token: String) throws -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return req
    }

    private func ensureOK(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SpotifyError.http(status: status, body: body)
        }
    }

    // IMPORTANT: Match YOUR Mood enum.
    private func defaultGenres(for mood: Mood) -> [String] {
        switch mood {
        case .happy:       return ["happy", "pop", "dance", "party", "summer"]
        case .sad:         return ["sad", "acoustic", "piano", "singer-songwriter"]
        case .calm:        return ["chill", "ambient", "sleep", "new-age", "focus"]
        case .energetic:   return ["work-out", "edm", "dance", "electro", "techno"]
        case .angry:       return ["metal", "hard-rock", "punk", "rock"]
        case .anxious:     return ["ambient", "classical", "meditation", "calm"]
        case .melancholic: return ["blues", "indie", "alternative", "sad"]
        case .focused:     return ["focus", "instrumental", "lo-fi", "study"]
        case .nostalgic:   return ["indie", "folk", "acoustic", "singer-songwriter"]
        }
    }
}

// MARK: - Models

private struct RecommendationsResponse: Decodable { let tracks: [Track] }
private struct Track: Decodable { let id: String; let uri: String }
private struct PlaylistCreated: Decodable { let id: String; let external_urls: [String:String]? }

// MARK: - Errors

enum SpotifyError: Error, LocalizedError {
    case http(status: Int, body: String)
    case notAuthenticated
    var errorDescription: String? {
        switch self {
        case .http(let s, let b): return "Spotify HTTP \(s): \(b)"
        case .notAuthenticated:   return "Not authenticated with Spotify."
        }
    }
}

// MARK: - Tiny utilities

private extension Optional where Wrapped == URL {
    func unwrapped() throws -> URL {
        guard let self else { throw SpotifyError.http(status: -1, body: "Bad URL") }
        return self
    }
}
private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
