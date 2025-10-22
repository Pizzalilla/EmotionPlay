//
//  ErrorAlertView.swift
//  EmotionPlay
//
//  Error handling UI for mood detection failures
//

import SwiftUI

struct ErrorAlertView: View {
    let error: MoodDetectionError
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            ZStack {
                Circle()
                    .fill(errorColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: errorIcon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(errorColor)
            }
            .padding(.top, 32)
            
            // Error message
            VStack(spacing: 12) {
                Text(error.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(error.message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Suggestions
            if !error.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try this:")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    ForEach(error.suggestions, id: \.self) { suggestion in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.AppGreenAccent)
                                .font(.caption)
                            
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                )
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    dismiss()
                    onRetry()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Try Another Photo")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.AppGreenAccent, Color.AppGreen3],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.secondaryCard)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.AppBackground)
    }
    
    // MARK: - Computed Properties
    
    private var errorIcon: String {
        switch error {
        case .noFaceDetected:
            return "face.dashed"
        case .lowConfidence:
            return "questionmark.circle"
        case .invalidImage:
            return "photo.badge.exclamationmark"
        case .processingFailed:
            return "exclamationmark.triangle"
        }
    }
    
    private var errorColor: Color {
        switch error {
        case .noFaceDetected:
            return .orange
        case .lowConfidence:
            return .yellow
        case .invalidImage:
            return .red
        case .processingFailed:
            return .red
        }
    }
}
