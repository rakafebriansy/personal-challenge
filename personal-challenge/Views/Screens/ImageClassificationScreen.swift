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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    ZStack {
                        Rectangle()
                            .fill(Color(UIColor.quaternarySystemFill))
                        
                        if let image = viewModel.selectedImage {
                            let displayImage = showOriginalImage ? image : (viewModel.debugProcessedImage ?? image)
                            Image(uiImage: displayImage)
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.metering.unknown")
                                    .font(.largeTitle)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("No photo yet")
                                    .font(.system(.callout, design: .rounded).weight(.medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 8)
                
                if viewModel.selectedImage == nil {
                    HStack(spacing: 12) {
                        Button(action: {
                            isCameraPresented = true
                        }) {
                            Label("Camera", systemImage: "camera.fill")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(AppTheme.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        
                        PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                            Label("Gallery", systemImage: "photo.on.rectangle.angled")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(UIColor.systemGray2))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                } else {
                    HStack(spacing: 10) {
                        Button(action: {
                            showOriginalImage.toggle()
                        }) {
                            Image(systemName: "rectangle.2.swap")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(!showOriginalImage ? Color.blue : (colorScheme == .dark ? Color.white : Color.primary))
                                .frame(width: 40, height: 40)
                                .background(Color(UIColor.secondarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        
                        Button(action: {
                            viewModel.reset()
                            photoItem = nil
                            showOriginalImage = false
                        }) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.predictions.isEmpty ? "Instructions" : "Prediction Results")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    if viewModel.isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Analyzing image...")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    } else if viewModel.predictions.isEmpty {
                        Text(viewModel.statusMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    } else {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(Array(viewModel.predictions.enumerated()), id: \.element.id) { index, pred in
                                HStack(spacing: 6) {
                                    Image(systemName: index == 0 ? "checkmark.seal.fill" : (index == 1 ? "2.circle.fill" : "3.circle.fill"))
                                        .font(.caption)
                                        .foregroundStyle(index == 0 ? Color.green : Color.secondary)
                                    Text("\(pred.letter) (\(pred.confidence)%)")
                                        .font(.system(.caption, design: .rounded).weight(index == 0 ? .semibold : .regular))
                                        .foregroundStyle(AppTheme.textPrimary)
                                }
                            }
                        }
                    }
                    
                    if !viewModel.predictions.isEmpty {
                        Spacer(minLength: 0)
                        
                        HStack {
                            Spacer()
                            Text("AI may make mistakes")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: 90, alignment: .topLeading)
                .cardStyle()
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(AppTheme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Camera Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ThemeMenuButton()
                }
            }
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

#Preview("Light Mode") {
    ImageClassificationScreen()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ImageClassificationScreen()
        .preferredColorScheme(.dark)
}
