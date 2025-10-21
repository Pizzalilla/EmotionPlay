import Foundation

struct ReccoRecommendation: Decodable {
    let ids: [String]
}

struct ReccoTrackDetail: Decodable {
    let id: String
    let trackTitle: String
    let artists: [Artist]
    let href: String? // Spotify link if available
    struct Artist: Decodable { let name: String }
}

final class ReccoBeatsClient {
    private let base = URL(string: "https://api.reccobeats.com/v1")!

    // Fetch recommendation list
    func getRecommendations(seeds: [String], size: Int = 25) async throws -> [String] {
        var comps = URLComponents(url: base.appendingPathComponent("track/recommendation"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "seeds", value: seeds.joined(separator: ",")),
        ]
        let (data, response) = try await URLSession.shared.data(from: comps.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let recs = try JSONDecoder().decode(ReccoRecommendation.self, from: data)
        return recs.ids
    }

    // Fetch track detail
    func getTrackDetail(id: String) async throws -> ReccoTrackDetail {
        let url = base.appendingPathComponent("track/\(id)")
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ReccoTrackDetail.self, from: data)
    }

    // Extract Spotify URI from href
    func spotifyURI(from detail: ReccoTrackDetail) -> String? {
        guard let href = detail.href, let id = href.split(separator: "/").last else { return nil }
        return "spotify:track:\(id)"
    }
}
