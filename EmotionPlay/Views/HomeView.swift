//
//  HomeView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//  Updated with CalAI-inspired dark aesthetic
//

import SwiftUI
import PhotosUI
import UIKit

struct HomeView: View {
  @ObservedObject var vm: HomeViewModel
  var goToProfileConnect: () -> Void

  @State private var showSourceSheet = false
  @State private var showPhotoPicker = false
  @State private var showCamera = false
  @State private var selectedItem: PhotosPickerItem? = nil

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // Header with enhanced styling
          ModernHeader()
          
          // Enhanced upload card with glassmorphic design
          EnhancedUploadCard(
            tap: { showSourceSheet = true },
            imageData: vm.pickedImageData
          )
          
          // Mood stats if detected
          if let mood = vm.detectedMood {
            MoodStatsSection(mood: mood, confidence: vm.confidence)
          }
          
          // Result section with modern buttons
          ModernResultSection(
            vm: vm,
            connectTapped: { goToProfileConnect() },
            analyzeTapped: { Task { await vm.analyzeAndCreate() } }
          )
          
          Spacer(minLength: 40)
        }
        .padding()
      }
      .background(Color.appBackground.ignoresSafeArea())
      
      // Choose camera vs. library
      .confirmationDialog("Add Photo",
                          isPresented: $showSourceSheet,
                          titleVisibility: .visible) {
        Button("Take Photo") { showCamera = true }
        Button("Choose from Library") { showPhotoPicker = true }
        Button("Cancel", role: .cancel) { }
      }
      
      // Photo Library picker
      .photosPicker(isPresented: $showPhotoPicker,
                    selection: $selectedItem,
                    matching: .images)
      .onChange(of: selectedItem) { newValue in
        Task {
          guard let newValue,
                let data = try? await newValue.loadTransferable(type: Data.self) else { return }
          vm.pickedImageData = data
          vm.detectedMood = nil
          vm.createdPlaylist = nil
        }
      }
      
      // Camera
      .sheet(isPresented: $showCamera) {
        CameraPicker { image in
          if let data = image.jpegData(compressionQuality: 0.9) {
            vm.pickedImageData = data
            vm.detectedMood = nil
            vm.createdPlaylist = nil
          }
        }
      }
    }
  }
}

// MARK: - Enhanced UI Components

extension HomeView {
  fileprivate struct ModernHeader: View {
    var body: some View {
      VStack(spacing: 12) {
        HStack {
          HStack(spacing: 12) {
            // App icon
            RoundedRectangle(cornerRadius: 14)
              .fill(
                LinearGradient(
                  colors: [Color.appGreenAccent, Color.appGreen3],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 44, height: 44)
              .overlay(
                Image(systemName: "music.note")
                  .font(.system(size: 22, weight: .bold))
                  .foregroundColor(.white)
              )
              .shadow(color: Color.appGreenAccent.opacity(0.5), radius: 10, x: 0, y: 5)
            
            Text("EmotiPlay")
              .font(.system(size: 28, weight: .bold, design: .rounded))
              .foregroundColor(.white)
          }
          
          Spacer()
          
          // Streak indicator
          HStack(spacing: 8) {
            Image(systemName: "flame.fill")
              .foregroundColor(.orange)
            Text("0")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(Color.cardBackground)
          .cornerRadius(20)
        }
        .padding(.top, 8)
      }
    }
  }
  
  fileprivate struct EnhancedUploadCard: View {
    let tap: () -> Void
    let imageData: Data?
    
    var body: some View {
      Button(action: tap) {
        ZStack {
          if let imageData, let ui = UIImage(data: imageData) {
            // Image preview with overlay
            Image(uiImage: ui)
              .resizable()
              .scaledToFill()
              .frame(height: 320)
              .clipped()
              .overlay(
                LinearGradient(
                  colors: [.clear, .black.opacity(0.7)],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
            
            VStack {
              Spacer()
              VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                  .font(.system(size: 40, weight: .bold))
                  .foregroundColor(.white)
                  .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Text("Change Photo")
                  .font(.system(size: 18, weight: .bold, design: .rounded))
                  .foregroundColor(.white)
                  .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
              }
              .padding(.bottom, 30)
            }
          } else {
            // Empty state with dashed border
            VStack(spacing: 20) {
              ZStack {
                Circle()
                  .fill(Color.secondaryCard)
                  .frame(width: 100, height: 100)
                
                Image(systemName: "camera.fill")
                  .font(.system(size: 44, weight: .bold))
                  .foregroundColor(.white.opacity(0.6))
              }
              
              VStack(spacing: 8) {
                Text("How are you feeling?")
                  .font(.system(size: 24, weight: .bold, design: .rounded))
                  .foregroundColor(.white)
                
                Text("Upload or take a photo to discover your mood")
                  .font(.subheadline)
                  .foregroundColor(.gray)
                  .multilineTextAlignment(.center)
              }
            }
            .frame(height: 320)
            .frame(maxWidth: .infinity)
            .background(
              LinearGradient(
                colors: [Color.cardBackground, Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
              )
            )
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(
              imageData == nil ? Color.gray.opacity(0.3) : Color.appGreenAccent,
              style: StrokeStyle(lineWidth: 2, dash: imageData == nil ? [8, 8] : [])
            )
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
      }
      .buttonStyle(.plain)
    }
  }
  
  fileprivate struct MoodStatsSection: View {
    let mood: Mood
    let confidence: Double
    
    var body: some View {
      ModernCard {
        VStack(spacing: 20) {
          Text("Detected Mood")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
          
          HStack(spacing: 12) {
            StatsCircle(
              icon: moodEmoji(mood),
              value: mood.rawValue.capitalized,
              label: "Primary",
              gradient: moodGradient(mood)
            )
            
            StatsCircle(
              icon: "📊",
              value: "\(Int(confidence * 100))%",
              label: "Confidence",
              gradient: confidenceGradient(confidence)
            )
            
            StatsCircle(
              icon: "🎵",
              value: "Ready",
              label: "Playlist",
              gradient: LinearGradient(
                colors: [Color.appGreenAccent, Color.appGreen3],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
          }
        }
      }
    }
    
    private func moodEmoji(_ mood: Mood) -> String {
      switch mood {
      case .happy: return "😊"
      case .sad: return "😢"
      case .calm: return "😌"
      case .energetic: return "⚡"
      case .angry: return "😠"
      case .anxious: return "😰"
      case .melancholic: return "😔"
      case .focused: return "🎯"
      case .nostalgic: return "🌅"
      }
    }
    
    private func moodGradient(_ mood: Mood) -> LinearGradient {
      switch mood {
      case .happy: return Color.moodHappy
      case .sad: return Color.moodSad
      case .calm: return Color.moodCalm
      case .energetic: return Color.moodEnergetic
      default: return LinearGradient(
        colors: [Color.gray, Color.gray.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      }
    }
    
    private func confidenceGradient(_ confidence: Double) -> LinearGradient {
      if confidence >= 0.7 {
        return LinearGradient(
          colors: [Color.green, Color.green.opacity(0.7)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      } else if confidence >= 0.4 {
        return LinearGradient(
          colors: [Color.orange, Color.orange.opacity(0.7)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      } else {
        return LinearGradient(
          colors: [Color.red, Color.red.opacity(0.7)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    }
  }
  
  fileprivate struct ModernResultSection: View {
    @ObservedObject var vm: HomeViewModel
    let connectTapped: () -> Void
    let analyzeTapped: () -> Void
    
    var body: some View {
      VStack(spacing: 16) {
        // Created playlist card
        if let playlist = vm.createdPlaylist {
          ModernCard {
            VStack(spacing: 16) {
              HStack {
                VStack(alignment: .leading, spacing: 8) {
                  Text("✨ Playlist Created")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                  
                  Text(playlist.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                }
                Spacer()
              }
              
              if let url = playlist.url {
                Link(destination: url) {
                  HStack {
                    Image(systemName: "play.circle.fill")
                      .font(.system(size: 20))
                    Text("Open in Spotify")
                      .font(.system(size: 16, weight: .semibold))
                  }
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 14)
                  .background(Color.green)
                  .cornerRadius(14)
                }
              }
            }
          }
        }
        
        // Error message
        if let err = vm.errorMessage {
          Text(err)
            .font(.caption)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        
        // Action buttons
        if !vm.isAuthorized {
          ModernButton(
            title: "Connect Spotify",
            icon: "arrow.up.right.circle.fill",
            gradient: LinearGradient(
              colors: [Color.appGreen2, Color.appGreen3],
              startPoint: .leading,
              endPoint: .trailing
            ),
            action: connectTapped
          )
        } else {
          Button(action: analyzeTapped) {
            HStack(spacing: 12) {
              if vm.isLoading {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Analyzing...")
                  .font(.system(size: 16, weight: .semibold))
              } else {
                Image(systemName: "sparkles")
                  .font(.system(size: 18, weight: .semibold))
                Text("Analyze Photo & Create Playlist")
                  .font(.system(size: 16, weight: .semibold))
              }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
              LinearGradient(
                colors: [Color.appGreenAccent, Color.appGreen4],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.appGreenAccent.opacity(0.4), radius: 15, x: 0, y: 8)
          }
          .disabled(vm.pickedImageData == nil || vm.isLoading || !vm.isAuthorized)
          .opacity((vm.pickedImageData == nil || vm.isLoading || !vm.isAuthorized) ? 0.5 : 1.0)
        }
      }
    }
  }
  
  /// Simple camera wrapper
  fileprivate struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
      let picker = UIImagePickerController()
      picker.sourceType = .camera
      picker.delegate = context.coordinator
      picker.allowsEditing = false
      return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
      let onImage: (UIImage) -> Void
      init(onImage: @escaping (UIImage) -> Void) { self.onImage = onImage }
      func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.originalImage] as? UIImage { onImage(img) }
        picker.dismiss(animated: true)
      }
      func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
      }
    }
  }
}
