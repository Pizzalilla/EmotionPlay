import Foundation
import CryptoKit

enum PKCE {
  static func generateCodeVerifier(length: Int = 64) -> String {
    let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
    var result = String((0..<length).map { _ in chars.randomElement()! })
    if result.count < 43 { result += String(repeating: "a", count: 43 - result.count) }
    return String(result.prefix(128))
  }
  static func codeChallenge(from verifier: String) -> String {
    let data = Data(verifier.utf8)
    let hash = SHA256.hash(data: data)
    let base64 = Data(hash).base64EncodedString()
    return base64
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}

