//
//  HomeView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 4/10/2025.
//

import SwiftUI
import PhotosUI
import UIKit

struct HomeView: View {
  @ObservedObject var vm: HomeViewModel
  /// Switch to the Profile tab (to connect Spotify) when needed.
  var goToProfileConnect: () -> Void

  @State private var showSourceSheet = false
  @State private var showPhotoPicker = false
  @State private var showCamera = false
  @State private var selectedItem: PhotosPickerItem? = nil

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Header()

        // ⬇️ Upload card now previews the selected photo
        UploadCard(
          tap: { showSourceSheet = true },
          imageData: vm.pickedImageData
        )

        ResultSection(
          vm: vm,
          connectTapped: { goToProfileConnect() },
          analyzeTapped: { Task { await vm.analyzeAndCreate() } }
        )

        Spacer(minLength: 0)
      }
      .padding()
      .background(Color.appBackground.ignoresSafeArea())
      .foregroundStyle(.white)

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
          print("Picked image bytes:", data.count)
        }
      }

      // Camera
      .sheet(isPresented: $showCamera) {
        CameraPicker { image in
          if let data = image.jpegData(compressionQuality: 0.9) {
            vm.pickedImageData = data
            vm.detectedMood = nil
            vm.createdPlaylist = nil
            print("Captured image bytes:", data.count)
          }
        }
      }
    }
  }
}

// MARK: - Inline UI components

extension HomeView {
  fileprivate struct Header: View {
    var body: some View {
      VStack(spacing: 6) {
        Text("Emotion Play")
          .font(.system(size: 36, weight: .bold))
          .foregroundStyle(.white)
          .shadow(color: Color.appGreenAccent.opacity(0.6), radius: 10, y: 0)
        Text("Capture your mood, discover your sound")
          .foregroundStyle(.white.opacity(0.6))
          .font(.callout)
      }
      .padding(.top, 8)
    }
  }

  /// Upload card that shows a preview when `imageData` is available.
  fileprivate struct UploadCard: View {
    let tap: () -> Void
    let imageData: Data?

    var body: some View {
      Button(action: tap) {
        ZStack {
          if let imageData, let ui = UIImage(data: imageData) {
            Image(uiImage: ui)
              .resizable()
              .scaledToFill()
              .frame(maxWidth: .infinity, minHeight: 200)
              .clipped()
              .overlay(
                LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.6)],
                               startPoint: .top, endPoint: .bottom)
              )
            VStack(spacing: 10) {
              Image(systemName: "camera.fill").font(.system(size: 40, weight: .bold))
              Text("Change Photo").font(.title3).bold()
            }
          } else {
            VStack(spacing: 12) {
              Image(systemName: "camera.fill").font(.system(size: 40, weight: .bold))
              Text("Upload or Take Photo").font(.title3).bold()
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(
              LinearGradient(colors: [Color.appSurfaceDark, .black],
                             startPoint: .top, endPoint: .bottom)
            )
          }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .overlay(
          RoundedRectangle(cornerRadius: 24)
            .stroke(Color.appGreenAccent, style: StrokeStyle(lineWidth: 2, dash: [6,6]))
        )
      }
      .buttonStyle(.plain)
    }
  }

  fileprivate struct ResultSection: View {
    @ObservedObject var vm: HomeViewModel
    let connectTapped: () -> Void
    let analyzeTapped: () -> Void

    var body: some View {
      VStack(spacing: 14) {
        if let mood = vm.detectedMood {
          Text("Detected mood: \(mood.rawValue.capitalized) \(vm.confidence >= 0.01 ? "(\(Int(vm.confidence*100))%)" : "")")
            .font(.headline)
            .foregroundStyle(.white)
        }

        if let playlist = vm.createdPlaylist {
          CreatedPlaylistCard(playlist: playlist)
        }

        if let err = vm.errorMessage {
          Text(err)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }

        if !vm.isAuthorized {
          Button(action: connectTapped) {
            Label("Connect Spotify", systemImage: "arrow.up.right.square")
          }
          .buttonStyle(.borderedProminent)
          .tint(Color.appGreen2)
        } else {
          Button(action: analyzeTapped) {
            if vm.isLoading {
              ProgressView().tint(.white)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
            } else {
              Label("Analyze Photo & Create Playlist", systemImage: "sparkles")
            }
          }
          .buttonStyle(.borderedProminent)
          .tint(Color.appGreen4)
          .disabled(vm.pickedImageData == nil || vm.isLoading || !vm.isAuthorized)
        }
      }
    }
  }

  fileprivate struct CreatedPlaylistCard: View {
    let playlist: Playlist
    var body: some View {
      VStack(spacing: 8) {
        Text("Playlist created ✅").font(.headline)
        Text(playlist.name).font(.subheadline)
        if let url = playlist.url {
          Link("Open in Spotify", destination: url)
            .buttonStyle(.borderedProminent)
            .tint(Color.appGreen3)
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(Color.appSurfaceDark)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
