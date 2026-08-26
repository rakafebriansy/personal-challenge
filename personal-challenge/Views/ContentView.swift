//
//  ContentView.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 20/08/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @State private var isCameraPresented = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var viewModel = ScannerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Penerjemah Huruf Hijaiyah")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Foto Asli")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .cornerRadius(15)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundStyle(.gray)
                                Text("Belum ada foto")
                                    .foregroundStyle(.gray)
                            }
                        )
                }
                
                if let debugImage = viewModel.debugProcessedImage {
                    VStack(spacing: 6) {
                        Text("DEBUG: Gambar yang Dilihat Model (Grayscale + Invert)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Image(uiImage: debugImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                    }
                }
                
                if viewModel.isProcessing {
                    ProgressView("Menganalisis...")
                } else {
                    Text(viewModel.translationResult)
                        .font(.title)
                        .bold()
                        .foregroundStyle(.blue)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: {
                        isCameraPresented = true
                    }) {
                        Label("Kamera", systemImage: "camera")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Label("Galeri", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .onChange(of: photoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                viewModel.processImage(uiImage)
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .padding()
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker(image: Binding(
                get: { viewModel.selectedImage },
                set: { newImage in
                    if let image = newImage {
                        viewModel.processImage(image)
                    }
                }
            ))
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
