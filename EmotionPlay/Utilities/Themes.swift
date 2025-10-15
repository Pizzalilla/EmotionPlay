//
//  Themes.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import SwiftUI

extension Color {
  static let appBackground  = Color(hex: 0x1F2426)
  static let appGreen1      = Color(hex: 0x196E14)
  static let appGreen2      = Color(hex: 0x2A911E)
  static let appGreen3      = Color(hex: 0x4BB225)
  static let appGreen4      = Color(hex: 0x9FE11F)
  static let appGreenAccent = Color(hex: 0x50F335)
  static let appSurfaceDark = Color(hex: 0x2E2E2E)
  static let appTint        = appGreenAccent
}

extension Color {
  init(hex: UInt, alpha: Double = 1.0) {
    self.init(.sRGB,
      red:   Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >>  8) & 0xff) / 255,
      blue:  Double((hex >>  0) & 0xff) / 255,
      opacity: alpha
    )
  }
}

