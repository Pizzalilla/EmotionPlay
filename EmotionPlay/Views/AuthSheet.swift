//
//  AuthSheet.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import SwiftUI
import UIKit

struct AuthSheet: UIViewControllerRepresentable {
  let vm: RecommendViewModel
  func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    Task { await vm.connectSpotify(from: uiViewController) }
  }
}
