//
//  ScannerViewModel.swift
//  hijaiapp
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
    var errorMessage: String? = nil
    var predictions: [Prediction] = []
    var isProcessing: Bool = false
    
    private let mlService = MLVisionService()
    
    var isModelReady: Bool {
        mlService.isModelReady
    }
    
    func processImage(_ image: UIImage) {
        self.selectedImage = image
        self.isProcessing = true
        self.statusMessage = "Analyzing image..."
        self.errorMessage = nil
        self.predictions = []
        
        mlService.classifyImage(image: image) { [weak self] preds, errorMsg, debugImage in
            Task {
                @MainActor in
                self?.predictions = preds
                if let errorMsg = errorMsg, preds.isEmpty {
                    self?.errorMessage = errorMsg
                    self?.statusMessage = ""
                } else {
                    self?.errorMessage = nil
                    self?.statusMessage = preds.isEmpty ? (errorMsg ?? "No letter detected") : ""
                }
                self?.debugProcessedImage = debugImage
                self?.isProcessing = false
            }
        }
    }
    
    func setError(_ message: String) {
        self.errorMessage = message
        self.isProcessing = false
    }
    
    func reset() {
        self.selectedImage = nil
        self.debugProcessedImage = nil
        self.statusMessage = "Take a photo or select an image from the gallery to scan Hijaiyah letters."
        self.errorMessage = nil
        self.predictions = []
        self.isProcessing = false
    }
}
