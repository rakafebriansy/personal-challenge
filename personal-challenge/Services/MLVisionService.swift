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
    private var visionModel: VNCoreMLModel?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            let config = MLModelConfiguration()
            let coreMLModel = try AksaraJawaModel(configuration: config).model
            
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
                let result = "\(firstResult.identifier.uppercased()) (\(confidence)%)"
                
                completion(result)
            } else {
                completion("Letter is not recognized.")
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        Task {
            do {
                try handler.perform([request])
            } catch {
                completion("Failed to perform request: \(error.localizedDescription)")
            }
        }
    }
}
