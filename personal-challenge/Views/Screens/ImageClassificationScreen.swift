//
//  ImageClassificationScreen.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 27/08/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ImageClassificationScreen: View {
    @State private var isCameraPresented = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var viewModel = ScannerViewModel()
    @State private var showOriginalImage = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Deteksi Kamera")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(AppTheme.primaryBackground)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gambar Masukan")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    ZStack {
                        Rectangle()
                            .fill(Color(UIColor.quaternarySystemFill))
                        
                        if let image = viewModel.selectedImage {
                            let displayImage = showOriginalImage ? image : (viewModel.debugProcessedImage ?? image)
                            Image(uiImage: displayImage)
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                            
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showOriginalImage.toggle()
                                    }) {
                                        Image(systemName: showOriginalImage ? "photo.fill" : "photo")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(10)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .padding(12)
                                }
                                Spacer()
                            }
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.metering.unknown")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("Belum ada foto")
                                    .font(.system(.callout, design: .rounded).weight(.medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius - 4, style: .continuous))
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            isCameraPresented = true
                        }) {
                            Label("Kamera", systemImage: "camera.fill")
                        }
                        .primaryButtonStyle(color: AppTheme.accentColor)
                        
                        PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                            Label("Galeri", systemImage: "photo.on.rectangle.angled")
                        }
                        .primaryButtonStyle(color: Color(UIColor.systemGray2))
                        .onChange(of: photoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    viewModel.processImage(uiImage)
                                }
                            }
                        }
                        
                        if viewModel.selectedImage != nil {
                            Button(action: {
                                viewModel.reset()
                                photoItem = nil
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 52, height: 52)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .cardStyle()
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.predictions.isEmpty ? "Instruksi" : "Hasil Prediksi")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                
                if viewModel.isProcessing {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Menganalisis...")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else if viewModel.predictions.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(viewModel.predictions.enumerated()), id: \.element.id) { index, pred in
                            HStack(spacing: 8) {
                                Image(systemName: index == 0 ? "checkmark.seal.fill" : (index == 1 ? "2.circle.fill" : "3.circle.fill"))
                                    .foregroundStyle(index == 0 ? Color.green : Color.secondary)
                                Text("\(pred.letter) (\(pred.confidence)%)")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .padding()
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: -3)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(AppTheme.primaryBackground.ignoresSafeArea())
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
    ImageClassificationScreen()
}
