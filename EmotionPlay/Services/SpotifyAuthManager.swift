import Foundation
import AuthenticationServices

final class SpotifyAuthManager: NSObject, ObservableObject {
  // TODO: set these before running
  private let clientId: String = "YOUR_SPOTIFY_CLIENT_ID"
  private let redirectURI: String = "emotionplay://callback"

  private let scopes: String = [
    "playlist-modify-private",
    "playlist-modify-public"
  ].joined(separator: " ")

  @Published private(set) var accessToken: String? = nil
  private var refreshToken: String? = nil
  private var expiresAt: Date? = nil

  var isAuthorized: Bool { accessToken != nil && (expiresAt ?? .distantPast) > Date() }

  @MainActor
  func authorize(from viewController: UIViewController) async throws {
    let verifier = PKCE.generateCodeVerifier()
    let challenge = PKCE.codeChallenge(from: verifier)

    guard let authURL = URL(string:
      "https://accounts.spotify.com/authorize?client_id=\(clientId)" +
      "&response_type=code" +
      "&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)" +
      "&code_challenge_method=S256" +
      "&code_challenge=\(challenge)" +
      "&scope=\(scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
    ) else { throw URLError(.badURL) }

    let callbackScheme = URL(string: redirectURI)!.scheme!

    let code: String = try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(
        url: authURL,
        callbackURLScheme: callbackScheme
      ) { url, err in
        if let err = err { continuation.resume(throwing: err); return }
        guard
          let url = url,
          let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
        else { continuation.resume(throwing: URLError(.badServerResponse)); return }
        continuation.resume(returning: code)
      }
      session.presentationContextProvider = viewController as? ASWebAuthenticationPresentationContextProviding
      session.prefersEphemeralWebBrowserSession = true
      session.start()
    }

    try await exchangeCodeForToken(code: code, verifier: verifier)
  }

  private func exchangeCodeForToken(code: String, verifier: String) async throws {
    var req = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
    req.httpMethod = "POST"
    let body = [
      "client_id": clientId,
      "grant_type": "authorization_code",
      "code": code,
      "redirect_uri": redirectURI,
      "code_verifier": verifier
    ]
      .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)" }
      .joined(separator: "&")
    req.httpBody = body.data(using: .utf8)
    req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }

    struct TokenRes: Decodable { let access_token: String; let token_type: String; let expires_in: TimeInterval; let refresh_token: String? }
    let tok = try JSONDecoder().decode(TokenRes.self, from: data)
    accessToken = tok.access_token
    refreshToken = tok.refresh_token
    expiresAt = Date().addingTimeInterval(tok.expires_in)
  }

  func ensureFreshToken() async throws -> String {
    if let exp = expiresAt, exp.timeIntervalSinceNow > 60, let token = accessToken { return token }
    guard let refresh = refreshToken else { throw URLError(.userAuthenticationRequired) }

    var req = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
    req.httpMethod = "POST"
    let body = [
      "client_id": clientId,
      "grant_type": "refresh_token",
      "refresh_token": refresh
    ]
      .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)" }
      .joined(separator: "&")
    req.httpBody = body.data(using: .utf8)
    req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }

    struct TokenRes: Decodable { let access_token: String; let token_type: String; let expires_in: TimeInterval }
    let tok = try JSONDecoder().decode(TokenRes.self, from: data)
    accessToken = tok.access_token
    expiresAt = Date().addingTimeInterval(tok.expires_in)
    return tok.access_token
  }
}

