import Foundation
import UIKit

final class SpotifyAPIClient: MusicProviderClient {
  private let auth: SpotifyAuthManager
  init(auth: SpotifyAuthManager) { self.auth = auth }

  var isAuthorized: Bool { auth.isAuthorized }

  func authorize(from viewController: UIViewController) async throws {
    try await auth.authorize(from: viewController)
  }

  // MARK: - Helpers
  private func authedRequest(
    _ url: URL,
    method: String = "GET",
    jsonBody: [String: Any]? = nil
  ) async throws -> (Data, HTTPURLResponse) {
    let token = try await auth.ensureFreshToken()
    var req = URLRequest(url: url)
    req.httpMethod = method
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    if let jsonBody = jsonBody {
      req.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
      req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
    if http.statusCode == 429 { throw URLError(.cannotLoadFromNetwork) } // rate-limited
    guard (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
    return (data, http)
  }

  private func currentUserID() async throws -> String {
    let url = URL(string: "https://api.spotify.com/v1/me")!
    let (data, _) = try await authedRequest(url)
    struct Me: Decodable { let id: String }
    return try JSONDecoder().decode(Me.self, from: data).id
  }

  // Search (first result)
  private func searchArtistID(named name: String) async throws -> String? {
    let q = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
    let url = URL(string: "https://api.spotify.com/v1/search?q=\(q)&type=artist&limit=1")!
    let (data, _) = try await authedRequest(url)
    struct Resp: Decodable { struct Artists: Decodable { struct Item: Decodable { let id: String }; let items: [Item] }; let artists: Artists }
    return try JSONDecoder().decode(Resp.self, from: data).artists.items.first?.id
  }

  private func searchTrackID(title: String, artist: String) async throws -> String? {
    let q = "track:\(title) artist:\(artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let url = URL(string: "https://api.spotify.com/v1/search?q=\(q)&type=track&limit=1")!
    let (data, _) = try await authedRequest(url)
    struct Resp: Decodable { struct Tracks: Decodable { struct Item: Decodable { let id: String }; let items: [Item] }; let tracks: Tracks }
    return try JSONDecoder().decode(Resp.self, from: data).tracks.items.first?.id
  }

  // MARK: - Recommender
  func recommendTrackURIs(for mood: Mood, seedArtists: [String], seedTracks: [String], limit: Int) async throws -> [String] {
    // Resolve up to 5 seeds total
    var artistIDs: [String] = []
    for a in seedArtists.prefix(3) {
      if let id = try await searchArtistID(named: a) { artistIDs.append(id) }
    }

    var trackIDs: [String] = []
    for s in seedTracks.prefix(2) {
      let parts = s.split(separator: "–", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
      if parts.count == 2, let id = try await searchTrackID(title: parts[0], artist: parts[1]) { trackIDs.append(id) }
    }

    let f = features(for: mood)
    var comps = URLComponents(string: "https://api.spotify.com/v1/recommendations")!
    var items: [URLQueryItem] = [
      .init(name: "limit", value: String(limit)),
      .init(name: "target_valence", value: String((f.valence.lowerBound + f.valence.upperBound)/2)),
      .init(name: "target_energy", value: String((f.energy.lowerBound + f.energy.upperBound)/2)),
      .init(name: "target_danceability", value: String((f.danceability.lowerBound + f.danceability.upperBound)/2)),
      .init(name: "min_tempo", value: String(f.tempo.lowerBound)),
      .init(name: "max_tempo", value: String(f.tempo.upperBound))
    ]
    if !artistIDs.isEmpty { items.append(.init(name: "seed_artists", value: artistIDs.joined(separator: ","))) }
    if !trackIDs.isEmpty { items.append(.init(name: "seed_tracks", value: trackIDs.joined(separator: ","))) }
    if artistIDs.isEmpty && trackIDs.isEmpty { items.append(.init(name: "seed_genres", value: "pop")) } // safe default
    comps.queryItems = items

    let url = comps.url!
    let (data, _) = try await authedRequest(url)
    struct RecResp: Decodable { struct Track: Decodable { let uri: String }; let tracks: [Track] }
    let rec = try JSONDecoder().decode(RecResp.self, from: data)
    return rec.tracks.map { $0.uri }
  }

  // MARK: - Playlist creation
  func createPlaylist(name: String, description: String?, isPublic: Bool)
  async throws -> (id: String, url: URL?) {
    let userID = try await currentUserID()
    let url = URL(string: "https://api.spotify.com/v1/users/\(userID)/playlists")!
    let body: [String: Any] = ["name": name, "public": isPublic, "description": description ?? ""]
    let (data, _) = try await authedRequest(url, method: "POST", jsonBody: body)
    struct CreateResp: Decodable { let id: String; let external_urls: [String: String]? }
    let resp = try JSONDecoder().decode(CreateResp.self, from: data)
    let external = resp.external_urls?["spotify"].flatMap(URL.init(string:))
    return (resp.id, external)
  }

  func addTracks(to playlistID: String, uris: [String]) async throws {
    let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)/tracks")!
    let body: [String: Any] = ["uris": uris]
    _ = try await authedRequest(url, method: "POST", jsonBody: body)
  }
}

