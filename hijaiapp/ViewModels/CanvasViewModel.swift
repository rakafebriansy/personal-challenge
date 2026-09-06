//
//  CanvasViewModel.swift
//  hijaiapp
//
//  Created by Raka Febrian Syahputra on 26/08/26.
//

import Foundation
import SwiftUI

@Observable
class CanvasViewModel {
    var lines: [Line] = []
    
    var statusMessage: String = "Draw a Hijaiyah letter on the canvas above, then tap 'Check Drawing'."
    var errorMessage: String? = nil
    var predictions: [Prediction] = []
    var isProcessing: Bool = false
    var debugProcessedImage: UIImage? = nil
    
    private let mlService = MLVisionService()
    
    var isModelReady: Bool {
        mlService.isModelReady
    }
    
    func clear() {
        lines = []
        statusMessage = "Draw a Hijaiyah letter on the canvas above, then tap 'Check Drawing'."
        errorMessage = nil
        predictions = []
        debugProcessedImage = nil
    }
    
    func undo() {
        guard !lines.isEmpty else { return }
        lines.removeLast()
        statusMessage = "Draw a Hijaiyah letter on the canvas above, then tap 'Check Drawing'."
        errorMessage = nil
        predictions = []
        debugProcessedImage = nil
    }
    
    func checkDrawing(canvasSize: CGSize) {
        guard !lines.isEmpty else {
            errorMessage = "Canvas is empty! Draw a letter first."
            predictions = []
            return
        }
        
        isProcessing = true
        statusMessage = "Analyzing drawing..."
        errorMessage = nil
        predictions = []
        
        let image = renderCanvasToImage(size: canvasSize)
        
        mlService.classifyImage(image: image) {
            [weak self] preds, errorMsg, debugImage in
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
    
    private func renderCanvasToImage(size: CGSize) -> UIImage {
        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        var hasPoints = false
        
        for line in lines {
            for point in line.points {
                hasPoints = true
                minX = min(minX, point.x)
                minY = min(minY, point.y)
                maxX = max(maxX, point.x)
                maxY = max(maxY, point.y)
            }
        }
        
        guard hasPoints else {
            return UIGraphicsImageRenderer(size: size).image { ctx in
                UIColor.white.setFill()
                ctx.cgContext.fill(CGRect(origin: .zero, size: size))
            }
        }
        
        let padding: CGFloat = 40.0
        let rectWidth = (maxX - minX) + (padding * 2)
        let rectHeight = (maxY - minY) + (padding * 2)
        
        let squareSize = max(rectWidth, rectHeight)
        let finalSize = CGSize(width: squareSize, height: squareSize)
        
        let renderer = UIGraphicsImageRenderer(size: finalSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: finalSize))
            
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            cgContext.setStrokeColor(UIColor.black.cgColor)
            
            let offsetX = (squareSize - (maxX - minX)) / 2 - minX
            let offsetY = (squareSize - (maxY - minY)) / 2 - minY
            
            for line in lines {
                guard let firstPoint = line.points.first else { continue }
                
                let scalingFactor = max(1.0, squareSize / 200.0)
                cgContext.setLineWidth(line.lineWidth * scalingFactor)
                
                cgContext.beginPath()
                cgContext.move(to: CGPoint(x: firstPoint.x + offsetX, y: firstPoint.y + offsetY))
                
                for point in line.points.dropFirst() {
                    cgContext.addLine(to: CGPoint(x: point.x + offsetX, y: point.y + offsetY))
                }
                
                cgContext.strokePath()
            }
        }
    }
}
