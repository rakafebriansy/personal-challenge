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
    
    func classifyImage(image: CGImage, completion: @escaping (String) -> Void)  {
        guard let model = visionModel else {
            completion("Error: model is not ready yet.")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion("Error: \(error.localizedDescription)")
                return
            }
            
            if let results = request.results as? [VNClassificationObservation],
               let firstResult = results.first {
                let confidence = Int(firstResult.confidence * 100)
                let letterName = self.hijaiyahMapping[firstResult.identifier] ?? "Letter \(firstResult.identifier)"
                let result = "\(letterName) (\(confidence)%)"
                
                completion(result)
            } else {
                completion("Letter is not recognized.")
            }
        }
        
        request.imageCropAndScaleOption = .centerCrop
        
        // PRE-PROCESSING: Match photo with dataset format (Black Background, White Text)
        let ciImage = CIImage(cgImage: image)
        
        // 1. Convert to Grayscale and increase Contrast
        guard let grayscaleFilter = CIFilter(name: "CIColorControls") else { return }
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey)
        grayscaleFilter.setValue(2.0, forKey: kCIInputContrastKey) // High contrast
        
        // 2. Invert colors (White becomes Black, Black becomes White)
        guard let invertFilter = CIFilter(name: "CIColorInvert") else { return }
        invertFilter.setValue(grayscaleFilter.outputImage, forKey: kCIInputImageKey)
        
        guard let outputCIImage = invertFilter.outputImage,
              let processedCGImage = CIContext().createCGImage(outputCIImage, from: outputCIImage.extent) else {
            completion("Failed to process image.")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: processedCGImage, options: [:])
        
        Task {
            do {
                try handler.perform([request])
            } catch {
                completion("Failed to perform request: \(error.localizedDescription)")
            }
        }
    }
}
