//
//  ImageClassificationScreen.swift
//  hijaiapp
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
                                    .accessibilityHidden(true)
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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(viewModel.selectedImage != nil ? "Scanned letter image preview" : "No photo selected")
                    .accessibilityHint(viewModel.selectedImage != nil ? "Showing \(showOriginalImage ? "original photo" : "processed AI input")" : "Tap Camera or Gallery below to scan a Hijaiyah letter.")
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
                        .accessibilityLabel("Take photo with camera")
                        .accessibilityHint("Double tap to open camera and snap a photo of a written Hijaiyah letter")
                        
                        PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                            Label("Gallery", systemImage: "photo.on.rectangle.angled")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(UIColor.systemGray2))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .accessibilityLabel("Select photo from gallery")
                        .accessibilityHint("Double tap to choose a photo from your photo library")
                        .onChange(of: photoItem) { _, newItem in
                            Task {
                                do {
                                    if let data = try await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        viewModel.processImage(uiImage)
                                    } else if newItem != nil {
                                        viewModel.setError("Could not decode selected image file. Please try another image.")
                                    }
                                } catch {
                                    viewModel.setError("Failed to load photo: \(error.localizedDescription)")
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
                        .accessibilityLabel(showOriginalImage ? "Switch to processed AI view" : "Switch to original photo view")
                        .accessibilityHint("Double tap to toggle between original and processed image")
                        
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
                        .accessibilityLabel("Reset scan")
                        .accessibilityHint("Double tap to clear current photo and scan another")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.predictions.isEmpty ? (viewModel.errorMessage != nil ? "Error" : "Instructions") : "Prediction Results")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(viewModel.errorMessage != nil ? Color.red : AppTheme.textSecondary)
                        .accessibilityAddTraits(.isHeader)
                    
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.red)
                                .accessibilityHidden(true)
                            Text(error)
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundStyle(Color.red)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Error: \(error)")
                    } else if viewModel.isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Analyzing image...")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .accessibilityLabel("Analyzing image in progress")
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
                                        .accessibilityHidden(true)
                                    Text("\(pred.letter) (\(pred.confidence)%)")
                                        .font(.system(.caption, design: .rounded).weight(index == 0 ? .semibold : .regular))
                                        .foregroundStyle(AppTheme.textPrimary)
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Rank \(index + 1): \(pred.letter), \(pred.confidence) percent confidence")
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
                                .accessibilityLabel("Notice: AI predictions may make mistakes")
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
                        .accessibilityLabel("Appearance Settings")
                }
            }
        }
        .onChange(of: viewModel.predictions) { _, newPreds in
            if let top = newPreds.first {
                AccessibilityNotificationHelper.postAnnouncement("Scanned and predicted \(top.letter) with \(top.confidence) percent confidence")
            }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            if let error = error {
                AccessibilityNotificationHelper.postAnnouncement("Error: \(error)")
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
