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
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var canvasSize: CGSize = .zero
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    ZStack {
                        if showOriginalCanvas || viewModel.debugProcessedImage == nil {
                            DrawingCanvasView(lines: $viewModel.lines)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                                        .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06), lineWidth: 1)
                                )
                        } else if let debugImage = viewModel.debugProcessedImage {
                            Image(uiImage: debugImage)
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                        }
                    }
                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .onAppear {
                        canvasSize = geometry.size
                    }
                    .onChange(of: geometry.size) { oldSize, newSize in
                        canvasSize = newSize
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 8)
                
                HStack(spacing: 8) {
                    if !viewModel.lines.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                viewModel.undo()
                            }
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(isEditDisabled ? Color.gray.opacity(0.4) : AppTheme.accentColor)
                                .frame(width: 40, height: 40)
                                .background(isEditDisabled ? (colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)) : Color(UIColor.secondarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .disabled(isEditDisabled)
                        
                        Button(action: { showingClearAlert = true }) {
                            Image(systemName: "trash.fill")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(isEditDisabled ? Color.gray.opacity(0.4) : Color.red)
                                .frame(width: 40, height: 40)
                                .background(isEditDisabled ? (colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)) : Color(UIColor.secondarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .disabled(isEditDisabled)
                    }
                    
                    Button(action: {
                        if !showOriginalCanvas && viewModel.debugProcessedImage != nil {
                            showOriginalCanvas = true
                        } else {
                            viewModel.checkDrawing(canvasSize: canvasSize)
                            showOriginalCanvas = false
                        }
                    }) {
                        if !showOriginalCanvas && viewModel.debugProcessedImage != nil {
                            Label("Back to Canvas", systemImage: "pencil.and.outline")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(AppTheme.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            Label(viewModel.isProcessing ? "Analyzing..." : "Check Drawing", 
                                  systemImage: viewModel.isProcessing ? "hourglass" : "pencil.and.outline")
                                .font(.system(.footnote, design: .rounded).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background((!viewModel.lines.isEmpty && !viewModel.isProcessing) ? AppTheme.accentColor : (colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray4)))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .disabled(viewModel.lines.isEmpty || viewModel.isProcessing)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.predictions.isEmpty ? "Instructions" : "Prediction Results")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    if viewModel.predictions.isEmpty {
                        Text(viewModel.statusMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    } else {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(Array(viewModel.predictions.enumerated()), id: \.element.id) { index, pred in
                                HStack(spacing: 6) {
                                    Image(systemName: index == 0 ? "checkmark.seal.fill" : (index == 1 ? "2.circle.fill" : "3.circle.fill"))
                                        .font(.caption)
                                        .foregroundStyle(index == 0 ? Color.green : Color.secondary)
                                    Text("\(pred.letter) (\(pred.confidence)%)")
                                        .font(.system(.caption, design: .rounded).weight(index == 0 ? .semibold : .regular))
                                        .foregroundStyle(AppTheme.textPrimary)
                                }
                            }
                        }
                    }
                    
                    if !viewModel.predictions.isEmpty {
                        Spacer(minLength: 0)
                        
                        HStack {
                            Spacer()
                            Text("AI may make mistakes")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: 90, alignment: .topLeading)
                .cardStyle()
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(AppTheme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Hijaiyah Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ThemeMenuButton()
                }
            }
        }
        .alert("Clear Canvas?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    viewModel.clear()
                }
            }
        } message: {
            Text("All drawings on the canvas will be permanently deleted.")
        }
    }
    
    private var isShowingProcessedResult: Bool {
        !showOriginalCanvas && viewModel.debugProcessedImage != nil
    }
    
    private var isEditDisabled: Bool {
        viewModel.lines.isEmpty || viewModel.isProcessing || isShowingProcessedResult
    }
}

private struct CanvasSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

#Preview("Light Mode") {
    DrawingCanvasScreen()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    DrawingCanvasScreen()
        .preferredColorScheme(.dark)
}
