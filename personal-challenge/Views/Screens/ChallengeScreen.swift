//
//  ChallengeScreen.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import SwiftUI
import SwiftData

struct ChallengeScreen: View {
    @State private var viewModel = ChallengeViewModel()
    @State private var isPlayingChallenge: Bool = false
    @State private var showQuitAlert: Bool = false
    @State private var showResetHistoryAlert: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(sort: \ChallengeHistory.date, order: .reverse) private var historyList: [ChallengeHistory]
    
    var body: some View {
        NavigationStack {
            setupView
                .navigationTitle("Listening Challenge")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ThemeMenuButton()
                    }
                }
                .navigationDestination(isPresented: $isPlayingChallenge) {
                    activeGameView
                        .toolbar(.hidden, for: .tabBar)
                }
        }
        .background(AppTheme.primaryBackground.ignoresSafeArea())
    }
    
    private var setupView: some View {
        VStack(spacing: 8) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Questions: \(viewModel.questionCount)")
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Select 3 to 20 questions")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Stepper("", value: $viewModel.questionCount, in: 3...20)
                        .labelsHidden()
                    
                    Button(action: {
                        viewModel.startChallenge()
                        isPlayingChallenge = true
                    }) {
                        Label("Start", systemImage: "play.fill")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(AppTheme.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                
                Divider()
                
                AIEvaluationCardView(history: historyList)
            }
            .cardStyle()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accentColor)
                        Text("Recent History")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    if !historyList.isEmpty {
                        HStack(spacing: 6) {
                            Text("\(historyList.count) \(historyList.count == 1 ? "Session" : "Sessions")")
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.accentColor.opacity(0.12))
                                .foregroundStyle(AppTheme.accentColor)
                                .clipShape(Capsule())
                            
                            Button(action: {
                                showResetHistoryAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.red.opacity(0.85))
                                    .padding(3)
                            }
                        }
                    }
                }
                
                Divider()
                
                if historyList.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "trophy")
                            .font(.title)
                            .foregroundStyle(Color.secondary.opacity(0.35))
                        Text("No challenge history yet.\nStart your first session to track progress!")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(historyList) { item in
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(item.isPerfectScore ? Color.green.opacity(0.15) : (item.score >= 80 ? Color.orange.opacity(0.15) : AppTheme.accentColor.opacity(0.12)))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: item.isPerfectScore ? "trophy.fill" : (item.score >= 80 ? "star.fill" : "headphones"))
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(item.isPerfectScore ? Color.green : (item.score >= 80 ? Color.orange : AppTheme.accentColor))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.badgeTitle)
                                            .font(.system(.caption, design: .rounded).weight(.semibold))
                                            .foregroundStyle(AppTheme.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        
                                        HStack(spacing: 4) {
                                            Text(item.formattedDate)
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundStyle(AppTheme.textSecondary)
                                                .lineLimit(1)
                                                .layoutPriority(1)
                                            
                                            if !item.missedLetters.isEmpty {
                                                Text("•")
                                                    .font(.caption2)
                                                    .foregroundStyle(Color.secondary.opacity(0.5))
                                                Text("Missed: \(item.missedLetters.joined(separator: ", "))")
                                                    .font(.system(.caption2, design: .rounded).weight(.medium))
                                                    .foregroundStyle(Color.red.opacity(0.85))
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(item.score)")
                                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                                            .foregroundStyle(item.isPerfectScore ? Color.green : (item.score >= 80 ? Color.orange : AppTheme.accentColor))
                                            .lineLimit(1)
                                        
                                        Text("\(item.correctAnswers)/\(item.totalQuestions)")
                                            .font(.system(.caption2, design: .rounded).weight(.medium))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(Color(UIColor.systemGray5))
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .clipShape(Capsule())
                                            .lineLimit(1)
                                    }
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color(UIColor.tertiarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.02), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .cardStyle()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .alert("Reset Challenge History?", isPresented: $showResetHistoryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset All", role: .destructive) {
                resetHistory()
            }
        } message: {
            Text("All past challenge results and history will be permanently deleted.")
        }
    }
    
    private var activeGameView: some View {
        VStack(spacing: 0) {
            switch viewModel.state {
            case .playing:
                playingView
            case .finished:
                finishedView
            default:
                EmptyView()
            }
        }
        .background(AppTheme.primaryBackground.ignoresSafeArea())
        .navigationTitle(viewModel.state == .playing ? "Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questionCount)" : "Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.state == .playing)
        .toolbar {
            if viewModel.state == .playing {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showQuitAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .fontWeight(.semibold)
                            Text("Back")
                        }
                    }
                }
            }
        }
        .alert("Quit Challenge?", isPresented: $showQuitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Quit", role: .destructive) {
                isPlayingChallenge = false
                viewModel.resetToSetup()
            }
        } message: {
            Text("Your current progress will be lost. Are you sure you want to quit?")
        }
    }
    
    private var playingView: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questionCount)")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("Correct: \(viewModel.correctAnswersCount)")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.green)
                }
                
                ProgressView(value: Double(viewModel.currentQuestionIndex + 1), total: Double(viewModel.questionCount))
                    .tint(AppTheme.accentColor)
            }
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 8)
            
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(AppTheme.secondaryBackground)
                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.03), lineWidth: 1)
                    )
                
                VStack(spacing: 8) {
                    Text("Listen to the Letter Sound:")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Button(action: {
                        viewModel.playCurrentAudio()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentColor.opacity(0.12))
                                .frame(width: 68, height: 68)
                            
                            Image(systemName: viewModel.audioPlayer.isPlaying ? "waveform" : "speaker.wave.3.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.accentColor)
                                .symbolEffect(.bounce, value: viewModel.audioPlayer.isPlaying)
                        }
                    }
                    
                    Text("Tap button to listen again")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.vertical, 12)
            }
            .frame(height: 136)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if let question = viewModel.currentQuestion {
                VStack(spacing: 6) {
                    ForEach(question.options) { option in
                        Button(action: {
                            viewModel.selectOption(option)
                        }) {
                            HStack(spacing: 12) {
                                Text(option.arabic)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .frame(width: 28, alignment: .center)
                                
                                Text(option.letter.capitalized)
                                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                                
                                Spacer()
                                
                                if viewModel.isAnswerEvaluated {
                                    if option.letter == question.targetLetter {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                    } else if option == viewModel.selectedOption {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(buttonColor(for: option, target: question.targetLetter))
                            .foregroundStyle(buttonTextColor(for: option))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.04), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                        }
                        .disabled(viewModel.isAnswerEvaluated)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Spacer()
            
            if viewModel.isAnswerEvaluated {
                Button(action: {
                    viewModel.nextQuestion(modelContext: modelContext)
                }) {
                    Text(viewModel.currentQuestionIndex + 1 == viewModel.questionCount ? "See Final Results" : "Next Question")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppTheme.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text("Select the matching Arabic letter above")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var finishedView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(viewModel.finalScore == 100 ? Color.green.opacity(0.12) : AppTheme.accentColor.opacity(0.12))
                        .frame(width: 76, height: 76)
                    
                    Image(systemName: viewModel.finalScore == 100 ? "trophy.fill" : "rosette")
                        .font(.largeTitle)
                        .foregroundStyle(viewModel.finalScore == 100 ? Color.green : AppTheme.accentColor)
                }
                
                VStack(spacing: 4) {
                    Text(viewModel.finalScore == 100 ? "Outstanding! Perfect 🏆" : "Challenge Completed!")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    Text("Your Score:")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Text("\(viewModel.finalScore)")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundStyle(viewModel.finalScore == 100 ? Color.green : AppTheme.accentColor)
                    
                    Text("Answered \(viewModel.correctAnswersCount) of \(viewModel.questionCount) questions correctly (\(viewModel.finalScore)%)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                Button(action: {
                    isPlayingChallenge = false
                    viewModel.resetToSetup()
                }) {
                    Label("Back to Challenge Menu", systemImage: "arrow.counterclockwise")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(AppTheme.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .cardStyle()
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func buttonColor(for option: HijaiyahLetterOption, target: String) -> Color {
        guard viewModel.isAnswerEvaluated else {
            return AppTheme.secondaryBackground
        }
        
        if option.letter == target {
            return Color.green
        } else if option == viewModel.selectedOption {
            return Color.red
        } else {
            return AppTheme.secondaryBackground.opacity(0.5)
        }
    }
    
    private func buttonTextColor(for option: HijaiyahLetterOption) -> Color {
        guard viewModel.isAnswerEvaluated else {
            return AppTheme.textPrimary
        }
        
        if option == viewModel.selectedOption || option.letter == viewModel.currentQuestion?.targetLetter {
            return .white
        } else {
            return AppTheme.textSecondary
        }
    }
    
    private func resetHistory() {
        withAnimation {
            for item in historyList {
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }
}

#Preview("Light Mode") {
    ChallengeScreen()
        .modelContainer(for: ChallengeHistory.self, inMemory: true)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ChallengeScreen()
        .modelContainer(for: ChallengeHistory.self, inMemory: true)
        .preferredColorScheme(.dark)
}
