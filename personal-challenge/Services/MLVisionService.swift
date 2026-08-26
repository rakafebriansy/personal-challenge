//
//  MLVisionService.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 20/08/26.
//

import Foundation
import CoreML
import Vision
import CoreImage
import SwiftUI

// Map UIImage.Orientation to CGImagePropertyOrientation
// so CIImage.oriented() can correctly bake the rotation into pixels
private extension UIImage.Orientation {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .up:            return .up
        case .upMirrored:    return .upMirrored
        case .down:          return .down
        case .downMirrored:  return .downMirrored
        case .left:          return .left
        case .leftMirrored:  return .leftMirrored
        case .right:         return .right
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }
}

class MLVisionService {
    private let hijaiyahMapping: [String: String] = [
        "1": "Alif (أ)", "2": "Ba (ب)", "3": "Ta (ت)", "4": "Tsa (ث)", "5": "Jim (ج)",
        "6": "Ha (ح)", "7": "Kha (خ)", "8": "Dal (د)", "9": "Dzal (ذ)", "10": "Ra (ر)",
        "11": "Zai (ز)", "12": "Sin (س)", "13": "Syin (ش)", "14": "Shad (ص)", "15": "Dhad (ض)",
        "16": "Tha (ط)", "17": "Zha (ظ)", "18": "Ain (ع)", "19": "Ghain (غ)", "20": "Fa (ف)",
        "21": "Qaf (ق)", "22": "Kaf (ك)", "23": "Lam (ل)", "24": "Mim (م)", "25": "Nun (ن)",
        "26": "Ha (ه)", "27": "Waw (و)", "28": "Ya (ي)"
    ]
    
    private var visionModel: VNCoreMLModel?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            let coreMLModel = try ArabicHandwrittenClassifier_2(configuration: config).model
            visionModel = try VNCoreMLModel(for: coreMLModel)
            print("Load model successfully!")
        } catch {
            print("Fail to load model: \(error.localizedDescription)")
        }
    }
    
    func classifyImage(image: UIImage, completion: @escaping (String, UIImage?) -> Void) {
        guard let model = visionModel else {
            completion("Error: model is not ready yet.", nil)
            return
        }
        
        // Step 1: Get raw CGImage (no orientation metadata)
        guard let cgImage = image.cgImage else {
            completion("Failed to read CGImage.", nil)
            return
        }
        
        // Step 2: Create CIImage from CGImage, then EXPLICITLY bake the orientation
        // into the pixel data using .oriented() — this is more reliable than CIImage(image:)
        // because subsequent filters will operate on the already-corrected pixel layout.
        let rawCIImage = CIImage(cgImage: cgImage)
        let ciImage = rawCIImage.oriented(image.imageOrientation.cgImagePropertyOrientation)
        
        // Step 3: PRE-PROCESSING — match dataset format (Black Background, White Text)
        
        // 3a. Convert to Grayscale and increase Contrast
        guard let grayscaleFilter = CIFilter(name: "CIColorControls") else {
            completion("Failed to create grayscale filter.", nil)
            return
        }
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey)  // Remove all color → grayscale
        grayscaleFilter.setValue(2.0, forKey: kCIInputContrastKey)    // Boost contrast
        
        // 3b. Invert colors: white paper → black bg, black ink → white text
        guard let invertFilter = CIFilter(name: "CIColorInvert") else {
            completion("Failed to create invert filter.", nil)
            return
        }
        invertFilter.setValue(grayscaleFilter.outputImage, forKey: kCIInputImageKey)
        
        guard let outputCIImage = invertFilter.outputImage,
              let processedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) else {
            completion("Failed to create final processed image.", nil)
            return
        }
        
        // Debug image: shows exactly what the model sees
        let debugImage = UIImage(cgImage: processedCGImage)
        
        // Step 4: Run Vision request on the processed image
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion("Error: \(error.localizedDescription)", debugImage)
                return
            }
            if let results = request.results as? [VNClassificationObservation],
               let firstResult = results.first {
                let confidence = Int(firstResult.confidence * 100)
                let letterName = self.hijaiyahMapping[firstResult.identifier] ?? "Letter \(firstResult.identifier)"
                completion("\(letterName) (\(confidence)%)", debugImage)
            } else {
                completion("Letter is not recognized.", debugImage)
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: processedCGImage, options: [:])
        Task {
            do {
                try handler.perform([request])
            } catch {
                completion("Failed to perform request: \(error.localizedDescription)", debugImage)
            }
        }
    }
}
