import Foundation
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.emotionplay.spotify", category: "API")

// MARK: - Client
final class SpotifyAPIClient: MusicProviderClient, Recommender {
    private let auth: SpotifyAuthProviding
    private let base = URL(string: "https://api.spotify.com/v1")!
    private var cachedUserID: String?
    private var cachedUserMarket: String?

    init(auth: SpotifyAuthProviding) {
        self.auth = auth
    }

    // MARK: MusicProviderClient

    var isAuthorized: Bool {
        (try? auth.validTokenOrThrow()) != nil
    }

    func authorize(from viewController: UIViewController) async throws {
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
        logger.info(" Starting recommendations for mood: \(mood.rawValue)")
        let token = try auth.validTokenOrThrow()
        
        // Get user info
        let (userID, market) = try await getUserInfo(token: token)
        logger.info("🌍 User: \(userID), Market: \(market)")
        
        // Map mood to audio features
        let features = moodToAudioFeatures(mood)
        
        // Use ReccoBeats API for recommendations
        return try await fetchReccoBeatsRecommendations(
            valence: features.valence,
            energy: features.energy,
            limit: limit
        )
    }
    
    /// Fetch recommendations from ReccoBeats API
    /// ReccoBeats is a third-party API that provides Spotify recommendations
    /// Docs: http://reccobeats.com/docs/apis/get-recommendation
    private func fetchReccoBeatsRecommendations(
        valence: Double,
        energy: Double,
        limit: Int
    ) async throws -> [String] {
        
        // ReccoBeats endpoint
        guard let url = URL(string: "http://reccobeats.com/api/recommendation") else {
            throw SpotifyError.http(status: -1, body: "Invalid ReccoBeats URL")
        }
        
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        // ReccoBeats parameters
        comps.queryItems = [
            URLQueryItem(name: "valence", value: String(format: "%.2f", valence)),
            URLQueryItem(name: "energy", value: String(format: "%.2f", energy)),
            URLQueryItem(name: "limit", value: String(min(limit, 50)))
        ]
        
        var req = URLRequest(url: try comps.url.unwrapped())
        req.httpMethod = "GET"
        
        logger.info("🔍 ReccoBeats URL: \(req.url?.absoluteString ?? "unknown")")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse else {
            throw SpotifyError.http(status: -1, body: "No HTTP response")
        }
        
        logger.info("📡 ReccoBeats Response status: \(http.statusCode)")
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            logger.error("❌ ReccoBeats error: \(body)")
            throw SpotifyError.http(status: http.statusCode, body: body)
        }
        
        // ReccoBeats returns: { "tracks": [{ "id": "...", "uri": "...", "name": "..." }] }
        struct ReccoBeatsResponse: Decodable {
            let tracks: [ReccoTrack]
        }
        
        struct ReccoTrack: Decodable {
            let id: String
            let uri: String
            let name: String
        }
        
        let decoded = try JSONDecoder().decode(ReccoBeatsResponse.self, from: data)
        logger.info("✅ Got \(decoded.tracks.count) tracks from ReccoBeats")
        
        // Log some track names for debugging
        if !decoded.tracks.isEmpty {
            let trackNames = decoded.tracks.prefix(3).map { $0.name }.joined(separator: ", ")
            logger.info("📀 Sample tracks: \(trackNames)...")
        }
        
        return decoded.tracks.map { $0.uri }
    }
    
    /// Get user's ID and market (country code)
    private func getUserInfo(token: String) async throws -> (id: String, market: String) {
        // Return cached if available
        if let id = cachedUserID, let market = cachedUserMarket {
            return (id, market)
        }
        
        let req = try authorizedRequest(url: base.appendingPathComponent("me"), method: "GET", token: token)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp, data)
        
        struct Me: Decodable {
            let id: String
            let country: String?
            let product: String?
        }
        
        let me = try JSONDecoder().decode(Me.self, from: data)
        cachedUserID = me.id
        
        logger.info("✅ User: \(me.id), Country: \(me.country ?? "unknown"), Product: \(me.product ?? "unknown")")
        
        let market: String
        if let country = me.country, !country.isEmpty {
            market = country
            cachedUserMarket = country
        } else {
            logger.warning("⚠️ No country code available, using 'US' as default")
            market = "US"
            cachedUserMarket = "US"
        }
        
        return (me.id, market)
    }
    
    /// Maps mood to Spotify audio features (valence and energy)
    /// Valence: 0.0 (sad) to 1.0 (happy)
    /// Energy: 0.0 (calm) to 1.0 (energetic)
    private func moodToAudioFeatures(_ mood: Mood) -> (valence: Double, energy: Double) {
        switch mood {
        case .happy:
            return (valence: 0.8, energy: 0.7)
        case .sad:
            return (valence: 0.2, energy: 0.3)
        case .calm:
            return (valence: 0.5, energy: 0.3)
        case .energetic:
            return (valence: 0.7, energy: 0.9)
        case .angry:
            return (valence: 0.3, energy: 0.9)
        case .anxious:
            return (valence: 0.4, energy: 0.4)
        case .melancholic:
            return (valence: 0.3, energy: 0.4)
        case .focused:
            return (valence: 0.5, energy: 0.5)
        case .nostalgic:
            return (valence: 0.6, energy: 0.5)
        }
    }

    func createPlaylist(
        name: String,
        description: String?,
        isPublic: Bool
    ) async throws -> (id: String, url: URL?) {
        let token = try auth.validTokenOrThrow()
        
        // Get user ID (reuse cached or fetch)
        let (userID, _) = try await getUserInfo(token: token)

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

    // MARK: - Helpers

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
            logger.error("❌ HTTP \(status): \(body)")
            throw SpotifyError.http(status: status, body: body)
        }
    }
}

// MARK: - Models

private struct PlaylistCreated: Decodable {
    let id: String
    let external_urls: [String: String]?
}

// MARK: - Errors

enum SpotifyError: Error, LocalizedError {
    case http(status: Int, body: String)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .http(let s, let b): 
            return "Spotify API Error (\(s)): \(b.isEmpty ? "No details" : String(b.prefix(200)))"
        case .notAuthenticated:
            return "Not authenticated with Spotify. Please connect your account."
        }
    }
}

// MARK: - Utilities

private extension Optional where Wrapped == URL {
    func unwrapped() throws -> URL {
        guard let self else { throw SpotifyError.http(status: -1, body: "Invalid URL") }
        return self
    }
}
