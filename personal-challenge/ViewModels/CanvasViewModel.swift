//
//  CanvasViewModel.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 26/08/26.
//

import Foundation
import SwiftUI

@Observable
class CanvasViewModel {
    var lines: [Line] = []
    
    var statusMessage: String = "Gambar huruf di atas, lalu tekan 'Periksa'."
    var predictions: [Prediction] = []
    var isProcessing: Bool = false
    var debugProcessedImage: UIImage? = nil
    
    private let mlService = MLVisionService()
    
    func clear() {
        lines = []
        statusMessage = "Gambar huruf di atas, lalu tekan 'Periksa'."
        predictions = []
        debugProcessedImage = nil
    }
    
    func undo() {
        guard !lines.isEmpty else { return }
        lines.removeLast()
        statusMessage = "Gambar huruf di atas, lalu tekan 'Periksa'."
        predictions = []
        debugProcessedImage = nil
    }
    
    func checkDrawing(canvasSize: CGSize) {
        guard !lines.isEmpty else {
            statusMessage = "Kanvas masih kosong! Coba gambar dulu."
            predictions = []
            return
        }
        
        isProcessing = true
        statusMessage = "Menganalisis..."
        predictions = []
        
        let image = renderCanvasToImage(size: canvasSize)
        
        mlService.classifyImage(image: image) {
            [weak self] preds, errorMsg, debugImage in
            Task {
                @MainActor in
                self?.predictions = preds
                self?.statusMessage = errorMsg ?? ""
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
        
        // Beri padding agar gambar tidak menyentuh ujung (membantu model ML)
        let padding: CGFloat = 40.0
        let rectWidth = (maxX - minX) + (padding * 2)
        let rectHeight = (maxY - minY) + (padding * 2)
        
        // Buat kanvas menjadi persegi agar tidak terpotong (crop) oleh .centerCrop saat di-proses
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
            
            // Hitung offset agar gambar berada tepat di tengah kotak
            let offsetX = (squareSize - (maxX - minX)) / 2 - minX
            let offsetY = (squareSize - (maxY - minY)) / 2 - minY
            
            for line in lines {
                guard let firstPoint = line.points.first else { continue }
                
                // Gunakan ketebalan tinta yang sedikit lebih tebal secara proporsional
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
