//
//  PlaylistResultSheet.swift
//  EmotionPlay
//
//  Beautiful result pop-up showing detected mood and playlist
//

import SwiftUI

struct PlaylistResultSheet: View {
    let mood: Mood
    let confidence: Double
    let playlistName: String
    let playlistURL: URL?
    let onRetake: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.AppBackground, moodColor(mood).opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Success animation area
                        VStack(spacing: 20) {
                            // Mood emoji with animation
                            Text(moodEmoji(mood))
                                .font(.system(size: 100))
                                .scaleEffect(1.0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: mood)
                            
                            // Success message
                            VStack(spacing: 8) {
                                Text("Mood Detected!")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("We analyzed your photo")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Mood card
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Mood")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(mood.rawValue.capitalized)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                // Confidence badge
                                VStack(spacing: 4) {
                                    Text("\(Int(confidence * 100))%")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("confident")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(
                                    Circle()
                                        .fill(confidenceColor(confidence))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                        )
                                )
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.cardBackground)
                                    .shadow(color: moodColor(mood).opacity(0.3), radius: 20, x: 0, y: 10)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Playlist card
                        VStack(spacing: 20) {
                            // Playlist info
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "music.note.list")
                                        .font(.title2)
                                        .foregroundColor(.AppGreenAccent)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Your Playlist")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Text(playlistName)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                }
                                
                                Text("Created just for you based on your \(mood.rawValue) mood")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.secondaryCard)
                            )
                            
                            // Open in Spotify button
                            if let url = playlistURL {
                                Link(destination: url) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                        
                                        Text("Open in Spotify")
                                            .font(.system(size: 18, weight: .semibold))
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.AppGreenAccent, Color.AppGreen3],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: Color.AppGreenAccent.opacity(0.4), radius: 15, x: 0, y: 8)
                                }
                            }
                            
                            // Retake button
                            Button(action: {
                                dismiss()
                                onRetake()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                    
                                    Text("Take Another Photo")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(Color.secondaryCard)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func moodEmoji(_ mood: Mood) -> String {
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .calm: return "😌"
        case .energetic: return "⚡️"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .melancholic: return "😔"
        case .focused: return "🎯"
        case .nostalgic: return "🌅"
        }
    }
    
    private func moodColor(_ mood: Mood) -> Color {
        switch mood {
        case .happy: return .orange
        case .sad: return .blue
        case .calm: return .purple
        case .energetic: return .red
        case .angry: return .red
        case .anxious: return .yellow
        case .melancholic: return .indigo
        case .focused: return .green
        case .nostalgic: return .pink
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 {
            return .green.opacity(0.3)
        } else if confidence >= 0.4 {
            return .orange.opacity(0.3)
        } else {
            return .red.opacity(0.3)
        }
    }
}
