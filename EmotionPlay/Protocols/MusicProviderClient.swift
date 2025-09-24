//
//  MusicProviderClient.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import UIKit

public protocol MusicProviderClient: Recommender, PlaylistCreator {
  var isAuthorized: Bool { get }
  func authorize(from viewController: UIViewController) async throws
}
