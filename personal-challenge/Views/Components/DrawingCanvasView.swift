//
//  DrawingCanvasView.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 26/08/26.
//

import SwiftUI

struct DrawingCanvasView: View {
    @Binding var lines: [Line]
    
    var body: some View {
        Canvas {
            context, size in
            for line in lines {
                var path = Path()
                
                guard let firstPoint = line.points.first else {
                    continue
                }
                
                path.move(to: firstPoint)
                
                for point in line.points.dropFirst() {
                    path.addLine(to: point)
                }
                
                context.stroke(
                    path,
                    with: .color(line.color),
                    style: StrokeStyle(
                        lineWidth: line.lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .background(Color.white)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged {
                    value in
                    let newPoint = value.location
                    
                    if value.translation == .zero {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            lines.append(Line(points: [newPoint]))
                        }
                    } else {
                        guard let lastIndex = lines.indices.last else {
                            return
                        }
                        
                        lines[lastIndex].points.append(newPoint)
                    }
                }
        )
    }
}

#Preview {
    DrawingCanvasView(lines: .constant([]))
        .frame(width: 300, height: 300)
        .border(Color.gray)
}
