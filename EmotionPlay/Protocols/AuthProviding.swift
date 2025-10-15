//
//  AuthProviding.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 7/10/2025.
//

import Foundation

// Keep it internal (no `public` needed)
protocol SpotifyAuthProviding: AnyObject {
    func validTokenOrThrow() throws -> String
}
