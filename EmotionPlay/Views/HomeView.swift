//
//  HomeView.swift
//  EmotionPlay
//
//  Updated: Full screen sheets, direct redirect after analysis
//

import SwiftUI
import PhotosUI
import UIKit

struct HomeView: View {
  @ObservedObject var vm: HomeViewModel
  var goToProfileConnect: () -> Void
  var onPlaylistCreated: () -> Void

  @State private var showPhotoPicker = false
  @State private var showCamera = false
  @State private var selectedItem: PhotosPickerItem? = nil

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          ModernHeader()
          
          // Upload card - now opens sheet menu
          EnhancedUploadCard(
            tap: { showPhotoPicker = true },  // Changed to open picker directly
            imageData: vm.pickedImageData
          )
          
          // Result section
          ModernResultSection(
            vm: vm,
            connectTapped: { goToProfileConnect() },
            analyzeTapped: { 
              Task { 
                await vm.analyzeAndCreate()
                // ✨ Redirect immediately after analysis completes successfully
                if vm.createdPlaylist != nil {
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onPlaylistCreated()
                  }
                }
              } 
            }
          )
          
          Spacer(minLength: 40)
        }
        .padding()
      }
      .background(Color.AppBackground.ignoresSafeArea())
      
      // ✨ Photo picker as SHEET
      .sheet(isPresented: $showPhotoPicker) {
        PhotoPickerSheet(
          onImageSelected: { data in
            vm.pickedImageData = data
            vm.detectedMood = nil
            vm.createdPlaylist = nil
            vm.errorMessage = nil
            vm.detectionError = nil
            vm.showResultSheet = false
          },
          onCameraTapped: {
            showPhotoPicker = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              showCamera = true
            }
          }
        )
        .presentationDetents([.medium])
      }
      
      // Camera as sheet
      .sheet(isPresented: $showCamera) {
        CameraPicker { image in
          if let data = image.jpegData(compressionQuality: 0.9) {
            vm.pickedImageData = data
            vm.detectedMood = nil
            vm.createdPlaylist = nil
            vm.errorMessage = nil
            vm.detectionError = nil
            vm.showResultSheet = false
          }
        }
        .ignoresSafeArea()
      }
      
      // ✨ Error alert - FULL SCREEN, dismissible
      .sheet(item: $vm.detectionError) { error in
        ErrorAlertView(
          error: error,
          onRetry: {
            vm.resetForRetake()
            showPhotoPicker = true
          },
          onDismiss: {
            vm.detectionError = nil
          }
        )
        .presentationDetents([.large])  // Full screen
        .interactiveDismissDisabled(false)  // Can pull down to dismiss
      }
    }
  }
}

// MARK: - Photo Picker Sheet

struct PhotoPickerSheet: View {
  let onImageSelected: (Data) -> Void
  let onCameraTapped: () -> Void
  
  @Environment(\.dismiss) private var dismiss
  @State private var selectedItem: PhotosPickerItem?
  
  var body: some View {
    NavigationStack {
      ZStack {
        Color.AppBackground.ignoresSafeArea()
        
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
              .font(.system(size: 50))
              .foregroundColor(.AppGreenAccent)
            
            Text("Add Photo")
              .font(.title2.bold())
              .foregroundColor(.white)
            
            Text("Choose how you'd like to add a photo")
              .font(.subheadline)
              .foregroundColor(.gray)
          }
          .padding(.top, 40)
          
          Spacer()
          
          // Options
          VStack(spacing: 16) {
            // Camera button
            Button(action: {
              dismiss()
              onCameraTapped()
            }) {
              HStack(spacing: 16) {
                ZStack {
                  Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 50, height: 50)
                  
                  Image(systemName: "camera.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                  Text("Take Photo")
                    .font(.headline)
                    .foregroundColor(.white)
                  
                  Text("Use your camera")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                  .foregroundColor(.gray)
              }
              .padding(20)
              .background(Color.cardBackground)
              .cornerRadius(20)
            }
            .buttonStyle(.plain)
            
            // Photo library button
            PhotosPicker(selection: $selectedItem, matching: .images) {
              HStack(spacing: 16) {
                ZStack {
                  Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 50, height: 50)
                  
                  Image(systemName: "photo.on.rectangle")
                    .font(.title3)
                    .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                  Text("Choose from Library")
                    .font(.headline)
                    .foregroundColor(.white)
                  
                  Text("Pick an existing photo")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                  .foregroundColor(.gray)
              }
              .padding(20)
              .background(Color.cardBackground)
              .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .onChange(of: selectedItem) { newValue in
              Task {
                guard let newValue,
                      let data = try? await newValue.loadTransferable(type: Data.self) else { return }
                onImageSelected(data)
                dismiss()
              }
            }
          }
          .padding(.horizontal)
          
          Spacer()
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(.gray)
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
            RoundedRectangle(cornerRadius: 14)
              .fill(
                LinearGradient(
                  colors: [Color.AppGreenAccent, Color.AppGreen3],
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
              .shadow(color: Color.AppGreenAccent.opacity(0.5), radius: 10, x: 0, y: 5)
            
            Text("EmotionPlay")
              .font(.system(size: 28, weight: .bold, design: .rounded))
              .foregroundColor(.white)
          }
          
          Spacer()
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
            // Image preview
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
            // Empty state
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
                colors: [Color.cardBackground, Color.AppBackground],
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
              imageData == nil ? Color.gray.opacity(0.3) : Color.AppGreenAccent,
              style: StrokeStyle(lineWidth: 2, dash: imageData == nil ? [8, 8] : [])
            )
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
      }
      .buttonStyle(.plain)
    }
  }
  
  fileprivate struct ModernResultSection: View {
    @ObservedObject var vm: HomeViewModel
    let connectTapped: () -> Void
    let analyzeTapped: () -> Void
    
    var body: some View {
      VStack(spacing: 16) {
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
              colors: [Color.AppGreen2, Color.AppGreen3],
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
                colors: [Color.AppGreenAccent, Color.AppGreen4],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.AppGreenAccent.opacity(0.4), radius: 15, x: 0, y: 8)
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
