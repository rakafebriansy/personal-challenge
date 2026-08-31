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

struct Prediction: Identifiable, Hashable {
    let id = UUID()
    let letter: String
    let confidence: Int
}

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
    
    private let ciContext = CIContext()
    
    func classifyImage(image: UIImage, completion: @escaping ([Prediction], String?, UIImage?) -> Void) {
        guard let model = visionModel else {
            completion([], "Error: model is not ready yet.", nil)
            return
        }
        
        // Step 1: Get raw CGImage
        guard let cgImage = image.cgImage else {
            completion([], "Failed to read CGImage.", nil)
            return
        }
        
        // Step 2: Bake orientation into the pixel data using CIImage.oriented()
        let rawCIImage = CIImage(cgImage: cgImage)
        let orientedCIImage = rawCIImage.oriented(image.imageOrientation.cgImagePropertyOrientation)
        guard let orientedCGImage = ciContext.createCGImage(orientedCIImage, from: orientedCIImage.extent) else {
            completion([], "Failed to process image orientation.", nil)
            return
        }
        
        // Step 3: PRE-PROCESSING — Adaptive Binarization (Pure Black Background, Pure White Text)
        // Ensures yellow paper, white paper, shadows, and varying lighting produce crisp binary images.
        guard let binarizedCGImage = binarizeForClassifier(cgImage: orientedCGImage, targetSize: 360) else {
            completion([], "Failed to binarize image.", nil)
            return
        }
        
        // Debug image: shows exactly what the model sees (Clean Black and White)
        let debugImage = UIImage(cgImage: binarizedCGImage)
        
        // Step 4: Run Vision request on the processed binary image
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion([], "Error: \(error.localizedDescription)", debugImage)
                return
            }
            if let results = request.results as? [VNClassificationObservation] {
                let top3 = results.prefix(3)
                var predictions: [Prediction] = []
                for result in top3 {
                    let confidence = Int(result.confidence * 100)
                    let letterName = self.hijaiyahMapping[result.identifier] ?? "Letter \(result.identifier)"
                    predictions.append(Prediction(letter: letterName, confidence: confidence))
                }
                completion(predictions, nil, debugImage)
            } else {
                completion([], "Letter is not recognized.", debugImage)
            }
        }
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cgImage: binarizedCGImage, options: [:])
        Task {
            do {
                try handler.perform([request])
            } catch {
                completion([], "Failed to perform request: \(error.localizedDescription)", debugImage)
            }
        }
    }
    
    /// Converts input image to pure black-and-white (binary) format matching the model training dataset:
    /// Background = 0 (Pure Black), Text Stroke = 255 (Pure White).
    /// Uses Bradley-Roth Adaptive Thresholding with integral image for robust performance across yellow/white paper and shadows.
    private func binarizeForClassifier(cgImage: CGImage, targetSize: Int = 360) -> CGImage? {
        let origWidth = cgImage.width
        let origHeight = cgImage.height
        let minDim = min(origWidth, origHeight)
        let cropRect = CGRect(
            x: (origWidth - minDim) / 2,
            y: (origHeight - minDim) / 2,
            width: minDim,
            height: minDim
        )
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        
        var grayData = [UInt8](repeating: 0, count: targetSize * targetSize)
        let grayColorSpace = CGColorSpaceCreateDeviceGray()
        guard let grayCtx = CGContext(
            data: &grayData,
            width: targetSize,
            height: targetSize,
            bitsPerComponent: 8,
            bytesPerRow: targetSize,
            space: grayColorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        
        grayCtx.interpolationQuality = .high
        grayCtx.draw(croppedCGImage, in: CGRect(x: 0, y: 0, width: targetSize, height: targetSize))
        
        // 1. Polarity check: check border average to see if image is already light-on-dark
        var borderSum = 0
        var borderCount = 0
        for x in 0..<targetSize {
            borderSum += Int(grayData[x]) + Int(grayData[(targetSize - 1) * targetSize + x])
            borderCount += 2
        }
        for y in 1..<(targetSize - 1) {
            borderSum += Int(grayData[y * targetSize]) + Int(grayData[y * targetSize + (targetSize - 1)])
            borderCount += 2
        }
        let borderAvg = borderSum / max(1, borderCount)
        let isDarkBackground = borderAvg < 100
        
        if isDarkBackground {
            for i in 0..<(targetSize * targetSize) {
                grayData[i] = 255 - grayData[i]
            }
        }
        
        // 2. Compute Integral Image for fast local mean computation
        var integral = [Int32](repeating: 0, count: targetSize * targetSize)
        for y in 0..<targetSize {
            var sum: Int32 = 0
            let row = y * targetSize
            let prevRow = (y - 1) * targetSize
            for x in 0..<targetSize {
                sum += Int32(grayData[row + x])
                if y == 0 {
                    integral[row + x] = sum
                } else {
                    integral[row + x] = integral[prevRow + x] + sum
                }
            }
        }
        
        // 3. Bradley-Roth Adaptive Thresholding
        let S = max(15, targetSize / 7)
        let s2 = S / 2
        let thresholdPercent: Float = 0.12
        let t = 1.0 - thresholdPercent
        
        var outputData = [UInt8](repeating: 0, count: targetSize * targetSize)
        
        for y in 0..<targetSize {
            let y1 = max(0, y - s2)
            let y2 = min(targetSize - 1, y + s2)
            let row = y * targetSize
            
            for x in 0..<targetSize {
                let x1 = max(0, x - s2)
                let x2 = min(targetSize - 1, x + s2)
                let count = Int32((x2 - x1 + 1) * (y2 - y1 + 1))
                
                let d = integral[y2 * targetSize + x2]
                let c = (x1 > 0) ? integral[y2 * targetSize + (x1 - 1)] : 0
                let b = (y1 > 0) ? integral[(y1 - 1) * targetSize + x2] : 0
                let a = (x1 > 0 && y1 > 0) ? integral[(y1 - 1) * targetSize + (x1 - 1)] : 0
                
                let sum = d - b - c + a
                let val = Int32(grayData[row + x])
                let avg = sum / count
                
                // Pixel is ink if it is darker than local average AND has a minimum contrast delta
                if Float(val * count) < Float(sum) * t && (avg - val) >= 14 {
                    outputData[row + x] = 255 // Pure White text
                } else {
                    outputData[row + x] = 0   // Pure Black background
                }
            }
        }
        
        guard let outCtx = CGContext(
            data: &outputData,
            width: targetSize,
            height: targetSize,
            bitsPerComponent: 8,
            bytesPerRow: targetSize,
            space: grayColorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        
        return outCtx.makeImage()
    }
}
