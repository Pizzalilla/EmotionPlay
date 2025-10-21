//
//  AuthProviding.swift
//  EmotionPlay
//
//  Updated for Spotify OAuth integration
//

import Foundation
import UIKit

protocol SpotifyAuthProviding: AnyObject {
    /// Returns a valid OAuth token or throws if none is available.
    func validTokenOrThrow() throws -> String

    /// Starts the Spotify authorization flow (login screen).
    func authorize(from presenter: UIViewController) async throws

    /// Whether the user is currently authorized (has a valid token).
    var isAuthorized: Bool { get }
}
