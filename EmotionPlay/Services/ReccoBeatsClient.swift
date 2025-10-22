import Foundation

// Shapes
struct ReccoRecsEnvelope: Decodable {
    let content: [ReccoShortTrack]
}
struct ReccoShortTrack: Decodable {
    let id: String
    let trackTitle: String?
    let href: String?                 // Spotify track URL (optional)
    let artists: [Artist]?
    struct Artist: Decodable { let name: String }
}

struct ReccoTrackDetail: Decodable {
    let id: String
    let trackTitle: String
    let artists: [Artist]
    let href: String?                 // Spotify link if available
    struct Artist: Decodable { let name: String }
}

final class ReccoBeatsClient {
    private let base = URL(string: "https://api.reccobeats.com/v1")!

    /// Returns BOTH: Recco IDs and any inline Spotify hrefs (to avoid extra round trips)
    func getRecommendations(seeds: [String], size: Int = 25) async throws -> [ReccoShortTrack] {
        var comps = URLComponents(url: base.appendingPathComponent("track/recommendation"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "seeds", value: seeds.joined(separator: ",")),
        ]

        let (data, response) = try await URLSession.shared.data(from: comps.url!)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "ReccoBeats", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "recommendation \(http.statusCode): \(body)"])
        }

        // Real shape: { content: [ ...track objects... ] }
        do {
            return try JSONDecoder().decode(ReccoRecsEnvelope.self, from: data).content
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw NSError(domain: "ReccoBeats", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "recommendation decode failed: \(error). Body: \(body)"])
        }
    }

    func getTrackDetail(id: String) async throws -> ReccoTrackDetail {
        let url = base.appendingPathComponent("track/\(id)")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "ReccoBeats", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "track \(http.statusCode): \(body)"])
        }

        do {
            return try JSONDecoder().decode(ReccoTrackDetail.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw NSError(domain: "ReccoBeats", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "track decode failed for \(id): \(error). Body: \(body)"])
        }
    }

    /// href → spotify:track:ID
    func spotifyURI(fromHref href: String?) -> String? {
        guard let href, let id = href.split(separator: "/").last else { return nil }
        return "spotify:track:\(id)"
    }
}

