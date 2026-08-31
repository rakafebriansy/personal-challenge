//
//  DrawingCanvasScreen.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 27/08/26.
//

import SwiftUI

struct DrawingCanvasScreen: View {
    @State private var viewModel = CanvasViewModel()
    @State private var showingClearAlert = false
    @State private var showOriginalCanvas = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Kanvas Hijaiyah")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { viewModel.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(viewModel.lines.isEmpty ? Color.gray : AppTheme.accentColor)
                    }
                    .disabled(viewModel.lines.isEmpty || viewModel.isProcessing)
                    
                    Button(action: { showingClearAlert = true }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(viewModel.lines.isEmpty ? Color.gray : .red)
                    }
                    .disabled(viewModel.lines.isEmpty || viewModel.isProcessing)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(AppTheme.primaryBackground)
            
            GeometryReader { geometry in
                ZStack {
                    if showOriginalCanvas || viewModel.debugProcessedImage == nil {
                        DrawingCanvasView(lines: $viewModel.lines)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                    } else if let debugImage = viewModel.debugProcessedImage {
                        Image(uiImage: debugImage)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                    }
                    

                }
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            Button(action: {
                if !showOriginalCanvas && viewModel.debugProcessedImage != nil {
                    showOriginalCanvas = true
                } else {
                    viewModel.checkDrawing(canvasSize: UIScreen.main.bounds.size)
                    showOriginalCanvas = false
                }
            }) {
                if !showOriginalCanvas && viewModel.debugProcessedImage != nil {
                    Label("Kembali ke Canvas", systemImage: "arrow.uturn.backward")
                } else {
                    Label(viewModel.isProcessing ? "Menganalisis..." : "Periksa Tulisan", 
                          systemImage: viewModel.isProcessing ? "hourglass" : "sparkles.magnifyingglass")
                }
            }
            .primaryButtonStyle(isEnabled: !viewModel.lines.isEmpty && !viewModel.isProcessing)
            .disabled(viewModel.lines.isEmpty || viewModel.isProcessing)
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.predictions.isEmpty ? "Instruksi" : "Hasil Prediksi")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                
                if viewModel.predictions.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(viewModel.predictions.enumerated()), id: \.element.id) { index, pred in
                            HStack(spacing: 8) {
                                Image(systemName: index == 0 ? "checkmark.seal.fill" : (index == 1 ? "2.circle.fill" : "3.circle.fill"))
                                    .foregroundStyle(index == 0 ? Color.green : Color.secondary)
                                Text("\(pred.letter) (\(pred.confidence)%)")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .padding()
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: -3)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(AppTheme.primaryBackground.ignoresSafeArea())
        .alert("Hapus Kanvas?", isPresented: $showingClearAlert) {
            Button("Batal", role: .cancel) { }
            Button("Hapus", role: .destructive) {
                viewModel.clear()
            }
        } message: {
            Text("Semua coretan di kanvas akan dihapus permanen.")
        }
    }
}

private struct CanvasSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

#Preview {
    DrawingCanvasScreen()
}
