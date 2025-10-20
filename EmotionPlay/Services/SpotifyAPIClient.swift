import Foundation
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.emotionplay.spotify", category: "API")

// MARK: - Client
final class SpotifyAPIClient: MusicProviderClient, Recommender {
    private let auth: SpotifyAuthProviding
    private let base = URL(string: "https://api.spotify.com/v1")!
    private var cachedUserID: String?
    private var cachedTopArtists: [SpotifyArtist]?
    private var cachedTopTracks: [SpotifyTrack]?

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
        logger.info("🎵 Starting personalized recommendations for mood: \(mood.rawValue)")
        let token = try auth.validTokenOrThrow()

        // Get audio features for this mood
        let audioFeatures = moodToAudioFeatures(mood)
        logger.info("🎚️ Audio features: valence=\(String(format: "%.2f", audioFeatures.valence)), energy=\(String(format: "%.2f", audioFeatures.energy))")

        // Fetch user's top artists and tracks for personalization
        let topArtists = try await fetchTopArtists(token: token, limit: 5)
        let topTracks = try await fetchTopTracks(token: token, limit: 2)
        
        logger.info("✅ Got \(topArtists.count) top artists and \(topTracks.count) top tracks")

        // Build seeds (max 5 total across artists + tracks + genres)
        var seeds = RecommendationSeeds()
        
        // Prioritize: 2-3 artists, 0-2 tracks, 1-2 genres
        let artistIds = topArtists.prefix(3).map { $0.id }
        let trackIds = topTracks.prefix(2).map { $0.id }
        
        seeds.artistIds = Array(artistIds.prefix(3))
        seeds.trackIds = Array(trackIds.prefix(min(2, 5 - seeds.artistIds.count)))
        
        // Add genres from user preferences or extract from top artists
        let genresToUse: [String]
        if !preferredGenres.isEmpty {
            genresToUse = preferredGenres
        } else {
            // Extract genres from top artists
            genresToUse = topArtists.flatMap { $0.genres }.uniqued().prefix(3).map { $0 }
        }
        
        let remainingSlots = 5 - seeds.artistIds.count - seeds.trackIds.count
        seeds.genres = Array(genresToUse.prefix(max(1, remainingSlots)))
        
        logger.info("🌱 Seeds: \(seeds.artistIds.count) artists, \(seeds.trackIds.count) tracks, \(seeds.genres.count) genres")

        // Build recommendation request
        var comps = URLComponents(url: base.appendingPathComponent("recommendations"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 100))),
            URLQueryItem(name: "min_popularity", value: "20")
        ]
        
        // Add seeds
        if !seeds.artistIds.isEmpty {
            queryItems.append(URLQueryItem(name: "seed_artists", value: seeds.artistIds.joined(separator: ",")))
        }
        if !seeds.trackIds.isEmpty {
            queryItems.append(URLQueryItem(name: "seed_tracks", value: seeds.trackIds.joined(separator: ",")))
        }
        if !seeds.genres.isEmpty {
            queryItems.append(URLQueryItem(name: "seed_genres", value: seeds.genres.map { $0.lowercased() }.joined(separator: ",")))
        }
        
        // Add audio feature targets based on mood
        queryItems.append(contentsOf: [
            URLQueryItem(name: "target_valence", value: String(format: "%.2f", audioFeatures.valence)),
            URLQueryItem(name: "target_energy", value: String(format: "%.2f", audioFeatures.energy)),
            URLQueryItem(name: "target_danceability", value: String(format: "%.2f", audioFeatures.danceability))
        ])
        
        if let tempo = audioFeatures.tempo {
            queryItems.append(URLQueryItem(name: "target_tempo", value: String(Int(tempo))))
        }
        if let acousticness = audioFeatures.acousticness {
            queryItems.append(URLQueryItem(name: "target_acousticness", value: String(format: "%.2f", acousticness)))
        }
        
        comps.queryItems = queryItems

        let req = try authorizedRequest(url: try comps.url.unwrapped(), method: "GET", token: token)
        logger.info("🔍 Fetching recommendations from Spotify...")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp, data)

        let decoded = try JSONDecoder().decode(RecommendationsResponse.self, from: data)
        logger.info("✅ Got \(decoded.tracks.count) personalized tracks")
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

    // MARK: - Personalization Helpers
    
    /// Fetches user's top artists for personalization
    private func fetchTopArtists(token: String, limit: Int) async throws -> [SpotifyArtist] {
        // Return cached if available (cache for session)
        if let cached = cachedTopArtists {
            logger.info("📦 Using cached top artists (\(cached.count))")
            return cached
        }
        
        var comps = URLComponents(url: base.appendingPathComponent("me/top/artists"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "limit", value: String(min(limit, 50))),
            URLQueryItem(name: "time_range", value: "medium_term") // Last ~6 months
        ]
        
        let req = try authorizedRequest(url: try comps.url.unwrapped(), method: "GET", token: token)
        logger.info("🎤 Fetching user's top artists...")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp, data)
        
        struct TopArtistsResponse: Decodable {
            let items: [SpotifyArtist]
        }
        let response = try JSONDecoder().decode(TopArtistsResponse.self, from: data)
        cachedTopArtists = response.items
        
        logger.info("✅ Top artists: \(response.items.map { $0.name }.joined(separator: ", "))")
        return response.items
    }
    
    /// Fetches user's top tracks for personalization
    private func fetchTopTracks(token: String, limit: Int) async throws -> [SpotifyTrack] {
        // Return cached if available
        if let cached = cachedTopTracks {
            logger.info("📦 Using cached top tracks (\(cached.count))")
            return cached
        }
        
        var comps = URLComponents(url: base.appendingPathComponent("me/top/tracks"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "limit", value: String(min(limit, 50))),
            URLQueryItem(name: "time_range", value: "medium_term")
        ]
        
        let req = try authorizedRequest(url: try comps.url.unwrapped(), method: "GET", token: token)
        logger.info("🎵 Fetching user's top tracks...")
        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp, data)
        
        struct TopTracksResponse: Decodable {
            let items: [SpotifyTrack]
        }
        let response = try JSONDecoder().decode(TopTracksResponse.self, from: data)
        cachedTopTracks = response.items
        
        logger.info("✅ Top tracks: \(response.items.map { $0.name }.joined(separator: ", "))")
        return response.items
    }
    
    /// Maps mood to Spotify audio features for better recommendations
    private func moodToAudioFeatures(_ mood: Mood) -> AudioFeatures {
        switch mood {
        case .happy:
            return AudioFeatures(
                valence: 0.8,        // High positivity
                energy: 0.7,         // High energy
                danceability: 0.7,   // Danceable
                tempo: 120,          // Upbeat tempo
                acousticness: nil
            )
        case .sad:
            return AudioFeatures(
                valence: 0.2,        // Low positivity
                energy: 0.3,         // Low energy
                danceability: 0.3,   // Not very danceable
                tempo: 80,           // Slower tempo
                acousticness: 0.6    // More acoustic
            )
        case .calm:
            return AudioFeatures(
                valence: 0.5,        // Neutral positivity
                energy: 0.3,         // Low energy
                danceability: 0.4,   // Low danceability
                tempo: 90,           // Moderate tempo
                acousticness: 0.7    // Acoustic preference
            )
        case .energetic:
            return AudioFeatures(
                valence: 0.7,        // Positive
                energy: 0.9,         // Very high energy
                danceability: 0.8,   // Very danceable
                tempo: 140,          // Fast tempo
                acousticness: 0.1    // Electronic
            )
        case .angry:
            return AudioFeatures(
                valence: 0.3,        // Low positivity
                energy: 0.9,         // High energy
                danceability: 0.5,   // Moderate
                tempo: 130,          // Fast
                acousticness: 0.2    // Electric/rock
            )
        case .anxious:
            return AudioFeatures(
                valence: 0.4,        // Slightly negative
                energy: 0.4,         // Moderate energy
                danceability: 0.3,   // Low danceability
                tempo: 100,          // Moderate tempo
                acousticness: 0.6    // Calming acoustic
            )
        case .melancholic:
            return AudioFeatures(
                valence: 0.3,        // Low positivity
                energy: 0.4,         // Low-moderate energy
                danceability: 0.3,   // Low danceability
                tempo: 85,           // Slow tempo
                acousticness: 0.5    // Mixed
            )
        case .focused:
            return AudioFeatures(
                valence: 0.5,        // Neutral
                energy: 0.5,         // Moderate energy
                danceability: 0.4,   // Low danceability
                tempo: 110,          // Steady tempo
                acousticness: 0.4    // Instrumental preference
            )
        case .nostalgic:
            return AudioFeatures(
                valence: 0.6,        // Slightly positive
                energy: 0.5,         // Moderate energy
                danceability: 0.5,   // Moderate
                tempo: 100,          // Moderate tempo
                acousticness: 0.5    // Mixed
            )
        }
    }

    // MARK: - Helpers

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
}

// MARK: - Models

private struct RecommendationsResponse: Decodable {
    let tracks: [Track]
}

private struct Track: Decodable {
    let id: String
    let uri: String
    let name: String
}

private struct PlaylistCreated: Decodable {
    let id: String
    let external_urls: [String: String]?
}

/// User's top artist from Spotify
struct SpotifyArtist: Decodable {
    let id: String
    let name: String
    let genres: [String]
}

/// User's top track from Spotify
struct SpotifyTrack: Decodable {
    let id: String
    let name: String
    let uri: String
}

/// Audio features for mood-based recommendations
struct AudioFeatures {
    let valence: Double        // 0.0 - 1.0 (sad to happy)
    let energy: Double         // 0.0 - 1.0 (calm to energetic)
    let danceability: Double   // 0.0 - 1.0
    let tempo: Double?         // BPM (optional)
    let acousticness: Double?  // 0.0 - 1.0 (optional)
}

/// Seeds for Spotify recommendations (max 5 total)
struct RecommendationSeeds {
    var artistIds: [String] = []
    var trackIds: [String] = []
    var genres: [String] = []
    
    var totalCount: Int {
        artistIds.count + trackIds.count + genres.count
    }
}

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

// MARK: - Utilities

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
