// Services/SpotifyAuthManager.swift
import Foundation
import AuthenticationServices
import UIKit

final class SpotifyAuthManager: NSObject, ObservableObject {
  // MARK: - Configure these two
  private let clientId: String = "9aeb9fc2240446de9c56753250f1ef61"
  private let redirectURI: String = "emotionplay://callback"   // must match Info.plist URL scheme + Spotify dashboard

  // Scopes needed for playlist creation
  private let scopes: String = [
    "playlist-modify-private",
    "playlist-modify-public"
  ].joined(separator: " ")

  // MARK: - Tokens
  @Published private(set) var accessToken: String? = nil
  private var refreshToken: String? = nil
  private var expiresAt: Date? = nil

  // Anchor presenter to avoid blank/white sheet
  private let presenter = AuthPresenter()

  var isAuthorized: Bool {
    guard let token = accessToken, let exp = expiresAt else { return false }
    return !token.isEmpty && exp > Date()
  }

  /// Clears all stored tokens and resets authorization state
  func disconnect() {
    accessToken = nil
    refreshToken = nil
    expiresAt = nil
    cachedUserID = nil
    print("[SpotifyAuth] Disconnected - all tokens cleared")
  }

  // MARK: - User ID Cache
  private(set) var cachedUserID: String? = nil

  // MARK: - Public

  /// Starts PKCE auth using ASWebAuthenticationSession
  @MainActor
  func authorize(from viewController: UIViewController?) async throws {
    let verifier  = PKCE.generateCodeVerifier()
    let challenge = PKCE.codeChallenge(from: verifier)

    guard let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
      throw URLError(.badURL)
    }
    guard let encodedScopes = scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
      throw URLError(.badURL)
    }

    let urlStr =
      "https://accounts.spotify.com/authorize?client_id=\(clientId)" +
      "&response_type=code" +
      "&redirect_uri=\(encodedRedirect)" +
      "&code_challenge_method=S256" +
      "&code_challenge=\(challenge)" +
      "&scope=\(encodedScopes)"

    guard let authURL = URL(string: urlStr) else { throw URLError(.badURL) }
    let callbackScheme = URL(string: redirectURI)!.scheme!

    let code: String = try await withCheckedThrowingContinuation { cont in
      let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { url, err in
        if let err = err { cont.resume(throwing: err); return }
        guard
          let url = url,
          let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
        else {
          cont.resume(throwing: URLError(.badServerResponse)); return
        }
        cont.resume(returning: code)
      }
      session.presentationContextProvider = presenter
      session.prefersEphemeralWebBrowserSession = true
      session.start()
    }

    try await exchangeCodeForToken(code: code, verifier: verifier)
  }

  /// Ensures we have a valid token; refreshes if needed and returns an access token
  func ensureFreshToken() async throws -> String {
    if let exp = expiresAt, exp.timeIntervalSinceNow > 60, let token = accessToken {
      return token
    }
    guard let refreshToken else { throw URLError(.userAuthenticationRequired) }

    var req = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
    req.httpMethod = "POST"
    let body = [
      "client_id": clientId,
      "grant_type": "refresh_token",
      "refresh_token": refreshToken
    ]
      .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)" }
      .joined(separator: "&")
    req.httpBody = body.data(using: .utf8)
    req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    struct RefreshRes: Decodable { let access_token: String; let expires_in: TimeInterval }
    let tok = try JSONDecoder().decode(RefreshRes.self, from: data)
    accessToken = tok.access_token
    expiresAt = Date().addingTimeInterval(tok.expires_in)
    return tok.access_token
  }

  // MARK: - Private

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
    guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
      let text = String(data: data, encoding: .utf8) ?? ""
      print("Token exchange failed: \(text)")
      throw URLError(.badServerResponse)
    }
    struct TokenRes: Decodable {
      let access_token: String
      let expires_in: TimeInterval
      let refresh_token: String?
    }
    let tok = try JSONDecoder().decode(TokenRes.self, from: data)
    accessToken = tok.access_token
    refreshToken = tok.refresh_token ?? refreshToken
    expiresAt = Date().addingTimeInterval(tok.expires_in)
  }
}

/// Presentation anchor for ASWebAuthenticationSession to prevent blank/white screen.
final class AuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    // Key window of active scene
    return UIApplication.shared
      .connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow } ?? ASPresentationAnchor()
  }
}

extension SpotifyAuthManager: SpotifyAuthProviding {
    func validTokenOrThrow() throws -> String {
        // ⬇️ Use the real token property your manager exposes.
        // Common names: `accessToken`, `token`, `currentToken?.accessToken`, etc.
        if let token = self.accessToken, !token.isEmpty {
            return token
        }
        throw SpotifyError.notAuthenticated
    }
}
