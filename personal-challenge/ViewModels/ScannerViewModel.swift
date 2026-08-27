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
    var statusMessage: String = "Belum ada foto."
    var predictions: [Prediction] = []
    var isProcessing: Bool = false
    
    private let mlService = MLVisionService()
    
    func processImage(_ image: UIImage) {
        self.selectedImage = image
        self.isProcessing = true
        self.statusMessage = "Menganalisis..."
        self.predictions = []
        
        // Pass UIImage directly — orientation is handled inside MLVisionService via CIImage(image:)
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
        self.statusMessage = "Belum ada foto."
        self.predictions = []
        self.isProcessing = false
    }
}
