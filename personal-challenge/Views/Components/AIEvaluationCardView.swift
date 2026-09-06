//
//  AIEvaluationCardView.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 05/09/26.
//

import SwiftUI

struct AIEvaluationCardView: View {
    let history: [ChallengeHistory]
    @Environment(\.colorScheme) private var colorScheme
        
    @State private var evaluationText: String = ""
    @State private var isStreaming: Bool = false
    @State private var hasEvaluated: Bool = false
    @State private var isCopied: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
                    )
                
                if evaluationText.isEmpty && !isStreaming {
                    Text(history.isEmpty ? "Complete your listening challenges, then tap 'Evaluate' below to get smart AI practice recommendations." : "Tap 'Evaluate' below to analyze your quiz history and receive personalized AI practice recommendations.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(2)
                        .padding(8)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        Text(evaluationText)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                }
            }
            .frame(height: 85)
            
            HStack {
                if isStreaming {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Generating AI evaluation...")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(height: 28)
                    
                    Spacer()
                } else if evaluationText.isEmpty {
                    Spacer()
                    
                    Button(action: startEvaluation) {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                                .font(.caption)
                            Text("Evaluate")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(history.isEmpty ? (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)) : Color.orange.opacity(0.15))
                        .foregroundStyle(history.isEmpty ? AppTheme.textSecondary.opacity(0.5) : Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .disabled(history.isEmpty)
                } else {
                    Button(action: copyEvaluationText) {
                        Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(isCopied ? Color.green : AppTheme.textSecondary)
                            .frame(height: 28)
                    }
                    
                    Spacer()
                    
                    Button(action: startEvaluation) {
                        Label("Re-evaluate", systemImage: "arrow.clockwise")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(history.isEmpty ? AppTheme.textSecondary.opacity(0.5) : Color.orange)
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(history.isEmpty ? (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)) : Color.orange.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .disabled(history.isEmpty)
                }
            }
            .frame(height: 28)
        }
        .onChange(of: history.isEmpty) { _, isEmpty in
            if isEmpty {
                evaluationText = ""
                hasEvaluated = false
            }
        }
    }
    
    private func copyEvaluationText() {
        UIPasteboard.general.string = evaluationText
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                isCopied = false
            }
        }
    }

    private func startEvaluation() {
        guard !isStreaming else {
            return
        }
        
        evaluationText = ""
        isStreaming = true
        hasEvaluated = true
        isCopied = false
        
        let prompt = ChallengePromptBuilder.buildEvaluationPrompt(from: history)
        
        Task {
            do {
                let stream = LLMService.shared.generateStreaming(prompt: prompt)
                for try await token in stream {
                    await MainActor.run {
                        var cleanedToken = token
                        if cleanedToken.contains("<|") {
                            cleanedToken = cleanedToken.components(separatedBy: "<|").first ?? ""
                        }
                        
                        if evaluationText.isEmpty {
                            let trimmed = cleanedToken.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                evaluationText += trimmed
                            }
                        } else {
                            evaluationText += cleanedToken
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    evaluationText = "An error occurred while loading local AI model: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                var finalCleaned = evaluationText
                for stopTag in ["<|im_end|>", "<|im_end", "<|im_start|>", "<|im_start", "<|endoftext|>", "<|end|>"] {
                    finalCleaned = finalCleaned.replacingOccurrences(of: stopTag, with: "")
                }
                evaluationText = finalCleaned.trimmingCharacters(in: .whitespacesAndNewlines)
                isStreaming = false
            }
        }
    }
}
