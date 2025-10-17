//
//  AppTheme.swift
//  EmotionPlay
//
//  UI Design System - CalAI inspired dark aesthetic
//

import SwiftUI

// MARK: - App Theme Colors
extension Color {
    // Dark backgrounds
    static let AppBackground = Color(hex: "0A0A0F")
    static let cardBackground = Color(hex: "1C1C23")
    static let secondaryCard = Color(hex: "2A2A35")
    
    // Accent gradients (keep existing green theme)
    static let AppGreenAccent = Color(hex: "1DB954") // Spotify green
    static let AppGreen2 = Color(hex: "1ED760")
    static let AppGreen3 = Color(hex: "1AA34A")
    static let AppGreen4 = Color(hex: "178F3E")
    
    // Surface colors
    static let AppSurfaceDark = Color(hex: "1C1C23")
    static let AppTint = Color(hex: "1DB954")
    
    // Mood colors
    static let moodHappy = LinearGradient(
        colors: [Color(hex: "FFD93D"), Color(hex: "FFA726")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let moodSad = LinearGradient(
        colors: [Color(hex: "5E92F3"), Color(hex: "3B82F6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let moodCalm = LinearGradient(
        colors: [Color(hex: "A78BFA"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let moodEnergetic = LinearGradient(
        colors: [Color(hex: "F43F5E"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Helper for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Reusable Components
struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

struct GlassMorphicCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                Color.cardBackground.opacity(0.6)
                    .blur(radius: 10)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct StatsCircle: View {
    let icon: String
    let value: String
    let label: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.secondaryCard, lineWidth: 8)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .fill(gradient)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Text(icon)
                            .font(.system(size: 28))
                    )
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.secondaryCard)
        .cornerRadius(16)
    }
}

struct ModernButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}
