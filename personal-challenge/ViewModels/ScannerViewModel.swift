//
//  ScannerViewModel.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 20/08/26.
//

import CoreImage
import SwiftUI

@Observable
class ScannerViewModel {
    var selectedImage: UIImage? = nil
    var translationResult: String = "No result yet."
    var isProcessing: Bool = false
    
    private let mlService = MLVisionService()
    
    func processImage(_ image: UIImage) {
        self.selectedImage = image
        self.isProcessing = true
        self.translationResult = "Analyzing..."
        
        guard let cgImage = image.cgImage else {
            self.translationResult = "Failed to read image format."
            self.isProcessing = false
            return
        }
        
        mlService.classifyImage(image: cgImage) {
            [weak self] result in
            Task {
                @MainActor in
                self?.translationResult = result
                self?.isProcessing = false
            }
        }
    }
}
