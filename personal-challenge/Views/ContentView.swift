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
    @State private var viewModel = ScannerViewModel()
    @State private var photoItem: PhotosPickerItem? = nil
    
    var body: some View {
        VStack (spacing: 20) {
            Text("Penerjemah Huruf Hijaiyah")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(15)
                    .shadow(radius: 5)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
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
            
            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                Label("Pilih dari galeri", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 15)
                    )
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
        .padding()
        
    }

   
}

#Preview {
    ContentView()
}
