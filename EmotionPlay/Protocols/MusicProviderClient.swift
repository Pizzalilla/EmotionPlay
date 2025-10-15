//
//  MusicProviderClient.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import UIKit

/// Minimal auth surface your client provides (Spotify etc.)
protocol MusicProviderClient: AnyObject {
    var isAuthorized: Bool { get }
    func authorize(from viewController: UIViewController) async throws
}

