//
//  SharePlaylistView.swift
//  EmotionPlay
//
//  Share playlist with beautiful preview and native iOS share sheet
//

import SwiftUI

struct SharePlaylistView: View {
    let mood: Mood
    let playlistName: String
    let confidence: Double
    let spotifyURL: String?
    let imageData: Data?
    
    @Environment(\.dismiss) private var dismiss
    
    // Convenience initializer from HistoryItem
    init(item: HistoryItem) {
        self.mood = item.mood
        self.playlistName = item.playlistName
        self.confidence = item.confidence ?? 0.85
        self.spotifyURL = item.playlistURL?.absoluteString
        self.imageData = item.imageData
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Playlist card with image
                        VStack(spacing: 20) {
                            // Image or emoji
                            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(moodColor(mood), lineWidth: 3)
                                    )
                                    .shadow(color: moodColor(mood).opacity(0.5), radius: 20, x: 0, y: 10)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [moodColor(mood), moodColor(mood).opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 150, height: 150)
                                        .shadow(color: moodColor(mood).opacity(0.5), radius: 20, x: 0, y: 10)
                                    
                                    Text(moodEmoji(mood))
                                        .font(.system(size: 70))
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Text(playlistName)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text(mood.rawValue.capitalized)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(moodColor(mood))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(moodColor(mood).opacity(0.2))
                                    .cornerRadius(12)
                                
                                HStack(spacing: 16) {
                                    Label("Playlist", systemImage: "music.note.list")
                                    Text("•")
                                    Label("\(Int(confidence * 100))% match", systemImage: "sparkles")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                        .background(Color.cardBackground)
                        .cornerRadius(24)
                        
                        // Share message preview
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "quote.bubble.fill")
                                    .foregroundColor(.AppGreenAccent)
                                Text("Share Message Preview")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Text(shareText)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondaryCard)
                                .cornerRadius(12)
                        }
                        
                        // Info about sharing
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Your playlist link will be shared via native iOS share sheet")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
                
                // Fixed share button at bottom
                VStack {
                    Spacer()
                    
                    ShareLink(item: shareText) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Share Playlist")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.AppGreenAccent, Color.AppGreen4],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.AppGreenAccent.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.AppBackground.opacity(0), Color.AppBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                }
            }
            .navigationTitle("Share Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.AppGreenAccent)
                }
            }
        }
    }
    
    private var shareText: String {
        let moodEmoji = moodEmoji(mood)
        let spotifyLink = spotifyURL ?? ""
        
        return """
        \(moodEmoji) Check out my \(mood.rawValue.capitalized) playlist on EmotiPlay!
        
        "\(playlistName)"
        \(Int(confidence * 100))% mood match • Created with AI emotion recognition 🎭
        
        \(spotifyLink)
        
        #EmotiPlay #MoodPlaylist #\(mood.rawValue.capitalized)Vibes
        """
    }
    
    private func moodEmoji(_ mood: Mood) -> String {
        switch mood {
        case .happy: return "😊"
        case .sad: return "😢"
        case .energetic: return "⚡"
        case .angry: return "😠"
        case .calm: return "😌"
        case .anxious: return "😰"
        case .melancholic: return "🌧️"
        case .focused: return "🎯"
        case .nostalgic: return "💭"
        }
    }
    
    private func moodColor(_ mood: Mood) -> Color {
        switch mood {
        case .happy: return Color(hex: "FFA726")
        case .sad: return Color(hex: "3B82F6")
        case .energetic: return Color(hex: "EC4899")
        case .angry: return Color(hex: "EF4444")
        case .calm: return Color(hex: "8B5CF6")
        case .anxious: return Color(hex: "F59E0B")
        case .melancholic: return Color(hex: "6366F1")
        case .focused: return Color(hex: "10B981")
        case .nostalgic: return Color(hex: "F472B6")
        }
    }
}

