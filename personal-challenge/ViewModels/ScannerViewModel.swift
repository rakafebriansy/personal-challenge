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
    var translationResult: String = "No result yet."
    var isProcessing: Bool = false
    
    private let mlService = MLVisionService()
    
    func processImage(_ image: UIImage) {
        self.selectedImage = image
        self.isProcessing = true
        self.translationResult = "Analyzing..."
        
        // Pass UIImage directly — orientation is handled inside MLVisionService via CIImage(image:)
        mlService.classifyImage(image: image) { [weak self] result, debugImage in
            Task { @MainActor in
                self?.translationResult = result
                self?.debugProcessedImage = debugImage
                self?.isProcessing = false
            }
        }
    }
}
