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
    var debugProcessedImage: UIImage? = nil
    var statusMessage: String = "Take a photo or select an image from the gallery to scan Hijaiyah letters."
    var predictions: [Prediction] = []
    var isProcessing: Bool = false
    
    private let mlService = MLVisionService()
    
    func processImage(_ image: UIImage) {
        self.selectedImage = image
        self.isProcessing = true
        self.statusMessage = "Analyzing image..."
        self.predictions = []
        
        mlService.classifyImage(image: image) { [weak self] preds, errorMsg, debugImage in
            Task {
                @MainActor in
                self?.predictions = preds
                self?.statusMessage = errorMsg ?? ""
                self?.debugProcessedImage = debugImage
                self?.isProcessing = false
            }
        }
    }
    
    func reset() {
        self.selectedImage = nil
        self.debugProcessedImage = nil
        self.statusMessage = "Take a photo or select an image from the gallery to scan Hijaiyah letters."
        self.predictions = []
        self.isProcessing = false
    }
}
