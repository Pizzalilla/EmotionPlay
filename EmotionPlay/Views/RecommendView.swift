//
//  RecommendView.swift
//  EmotionPlay
//
//  Created by Kartikay Singh on 25/8/2025.
//

import SwiftUI

struct RecommendView: View {
  @ObservedObject var vm: RecommendViewModel
  @State private var presentAuth = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 18) {
        Picker("Mood", selection: $vm.selectedMood) {
          ForEach(Mood.allCases) { Text($0.rawValue.capitalized).tag($0) }
        }
        .pickerStyle(.segmented)
        .padding(.top, 8)

        HStack {
          Text("Tracks: \(vm.trackCount)")
            .foregroundStyle(.white)
          Slider(
            value: Binding(get: { Double(vm.trackCount) },
                           set: { vm.trackCount = Int($0) }),
            in: 10...40, step: 5
          )
        }

        if let created = vm.createdPlaylist {
          VStack(spacing: 8) {
            Text("Playlist created ✅").font(.headline)
            Text(created.name).font(.subheadline)
            if let url = created.url {
              Link("Open in Spotify", destination: url)
                .buttonStyle(.borderedProminent)
                .tint(.appGreen3)
            }
          }
          .padding()
          .frame(maxWidth: .infinity)
          .background(Color.appSurfaceDark)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        if let err = vm.errorMessage {
          Text(err).foregroundStyle(.red).multilineTextAlignment(.center)
        }

        if vm.isAuthorized == false {
          Button {
            presentAuth = true
          } label: {
            Label("Connect Spotify", systemImage: "arrow.up.right.square")
          }
          .buttonStyle(.borderedProminent)
          .tint(.appGreen2)
        } else {
          Button {
            Task { await vm.createMoodMix() }
          } label: {
            Label(vm.isLoading ? "Creating…" : "Create My Mood Mix", systemImage: "sparkles")
          }
          .buttonStyle(.borderedProminent)
          .tint(.appGreen4)
          .disabled(vm.isLoading)
        }

        Spacer(minLength: 0)
      }
      .padding()
      .background(Color.appBackground.ignoresSafeArea())
      .foregroundStyle(.white)
      .navigationTitle("Emotion Play")
      .sheet(isPresented: $presentAuth) { AuthSheet(vm: vm) }
    }
  }
}
