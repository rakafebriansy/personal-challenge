//
//  MLVisionService.swift
//  hijaiapp
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

enum MLVisionError: LocalizedError {
    case modelNotReady
    case modelLoadFailed(String)
    case imageProcessingFailed
    case classificationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotReady:
            return "Visual AI model is not ready. Please try again."
        case .modelLoadFailed(let details):
            return "Failed to load handwriting model: \(details)"
        case .imageProcessingFailed:
            return "Unable to process the image for analysis."
        case .classificationFailed(let details):
            return "Image classification failed: \(details)"
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
    private(set) var isModelReady: Bool = false
    private(set) var setupError: Error? = nil
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            let coreMLModel = try ArabicHandwrittenClassifier_2(configuration: config).model
            visionModel = try VNCoreMLModel(for: coreMLModel)
            isModelReady = true
            setupError = nil
            print("[MLVisionService] Arabic handwritten model loaded successfully!")
        } catch {
            setupError = error
            isModelReady = false
            print("[MLVisionService] Failed to load model: \(error.localizedDescription)")
        }
    }
    
    private let ciContext = CIContext()
    
    private func flattenTransparentBackground(_ image: UIImage) -> UIImage {
        let size = image.size
        guard size.width > 0 && size.height > 0 else { return image }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func classifyImage(image: UIImage, completion: @escaping ([Prediction], String?, UIImage?) -> Void) {
        guard let model = visionModel else {
            let errorMsg = setupError?.localizedDescription ?? MLVisionError.modelNotReady.localizedDescription
            completion([], errorMsg, nil)
            return
        }
        
        let opaqueImage = flattenTransparentBackground(image)
        
        guard let cgImage = opaqueImage.cgImage else {
            completion([], MLVisionError.imageProcessingFailed.localizedDescription, nil)
            return
        }
        
        let rawCIImage = CIImage(cgImage: cgImage)
        let orientedCIImage = rawCIImage.oriented(opaqueImage.imageOrientation.cgImagePropertyOrientation)
        guard let orientedCGImage = ciContext.createCGImage(orientedCIImage, from: orientedCIImage.extent) else {
            completion([], MLVisionError.imageProcessingFailed.localizedDescription, nil)
            return
        }
        
        guard let binarizedCGImage = binarizeForClassifier(cgImage: orientedCGImage, targetSize: 360) else {
            completion([], MLVisionError.imageProcessingFailed.localizedDescription, nil)
            return
        }
        
        let debugImage = UIImage(cgImage: binarizedCGImage)
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion([], MLVisionError.classificationFailed(error.localizedDescription).localizedDescription, debugImage)
                return
            }
            if let results = request.results as? [VNClassificationObservation], !results.isEmpty {
                let top3 = results.prefix(3)
                var predictions: [Prediction] = []
                for result in top3 {
                    let confidence = Int(result.confidence * 100)
                    let letterName = self.hijaiyahMapping[result.identifier] ?? "Letter \(result.identifier)"
                    predictions.append(Prediction(letter: letterName, confidence: confidence))
                }
                completion(predictions, nil, debugImage)
            } else {
                completion([], "Letter not recognized. Try drawing more clearly.", debugImage)
            }
        }
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cgImage: binarizedCGImage, options: [:])
        Task {
            do {
                try handler.perform([request])
            } catch {
                completion([], MLVisionError.classificationFailed(error.localizedDescription).localizedDescription, debugImage)
            }
        }
    }
    
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
        
        var grayData = [UInt8](repeating: 255, count: targetSize * targetSize)
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
        
        grayCtx.setFillColor(gray: 1.0, alpha: 1.0)
        grayCtx.fill(CGRect(x: 0, y: 0, width: targetSize, height: targetSize))
        grayCtx.interpolationQuality = .high
        grayCtx.draw(croppedCGImage, in: CGRect(x: 0, y: 0, width: targetSize, height: targetSize))
        
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
                
                if Float(val * count) < Float(sum) * t && (avg - val) >= 14 {
                    outputData[row + x] = 255
                } else {
                    outputData[row + x] = 0
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
