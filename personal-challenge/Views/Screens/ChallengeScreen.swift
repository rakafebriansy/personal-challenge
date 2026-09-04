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
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ChallengeHistory.date, order: .reverse) private var historyList: [ChallengeHistory]
    
    var body: some View {
        NavigationStack {
            setupView
                .navigationTitle("Voice Challenge")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $isPlayingChallenge) {
                    activeGameView
                        .toolbar(.hidden, for: .tabBar)
                }
        }
        .background(AppTheme.primaryBackground.ignoresSafeArea())
    }
    
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(AppTheme.accentColor)
                        Text("Challenge Settings")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    
                    Divider()
                    
                    Stepper(value: $viewModel.questionCount, in: 3...20) {
                        HStack {
                            Text("Questions:")
                                .font(.system(.body, design: .rounded))
                            Spacer()
                            Text("\(viewModel.questionCount) Questions")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .foregroundStyle(AppTheme.accentColor)
                        }
                    }
                    
                    Text("💡 Min 3, Max 20 questions. Answer all correctly to get a 100 score!")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Button(action: {
                        viewModel.startChallenge()
                        isPlayingChallenge = true
                    }) {
                        Label("Start Challenge", systemImage: "play.fill")
                    }
                    .primaryButtonStyle(color: AppTheme.accentColor)
                    .padding(.top, 8)
                }
                .cardStyle()
                .padding(.horizontal)
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(AppTheme.accentColor)
                        Text("Recent History")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        
                        if !historyList.isEmpty {
                            Text("\(historyList.count) Sessions")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    
                    Divider()
                    
                    if historyList.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "trophy")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.secondary.opacity(0.5))
                            Text("No challenge history yet.\nStart your first session!")
                                .font(.system(.callout, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(historyList) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.badgeTitle)
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(AppTheme.textPrimary)
                                        Text(item.formattedDate)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(item.score)")
                                            .font(.system(.title3, design: .rounded).weight(.bold))
                                            .foregroundStyle(item.isPerfectScore ? Color.green : AppTheme.accentColor)
                                        Text("\(item.correctAnswers)/\(item.totalQuestions) Correct")
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                
                                if item.id != historyList.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .cardStyle()
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
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
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questionCount)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text("Correct: \(viewModel.correctAnswersCount)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.green)
                }
                
                ProgressView(value: Double(viewModel.currentQuestionIndex + 1), total: Double(viewModel.questionCount))
                    .tint(AppTheme.accentColor)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(AppTheme.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 16) {
                    Text("Listen to the Letter Sound:")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Button(action: {
                        viewModel.playCurrentAudio()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentColor.opacity(0.12))
                                .frame(width: 96, height: 96)
                            
                            Image(systemName: viewModel.audioPlayer.isPlaying ? "waveform" : "speaker.wave.3.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.accentColor)
                                .symbolEffect(.bounce, value: viewModel.audioPlayer.isPlaying)
                        }
                    }
                    
                    Text("Tap button to listen again")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.vertical, 24)
            }
            .frame(height: 200)
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            if let question = viewModel.currentQuestion {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(question.options) { option in
                        Button(action: {
                            viewModel.selectOption(option)
                        }) {
                            VStack(spacing: 6) {
                                Text(option.arabic)
                                    .font(.system(size: 46, weight: .bold))
                                Text(option.letter.capitalized)
                                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(buttonColor(for: option, target: question.targetLetter))
                            .foregroundStyle(buttonTextColor(for: option))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        }
                        .disabled(viewModel.isAnswerEvaluated)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            if viewModel.isAnswerEvaluated {
                Button(action: {
                    viewModel.nextQuestion(modelContext: modelContext)
                }) {
                    Text(viewModel.currentQuestionIndex + 1 == viewModel.questionCount ? "See Final Results" : "Next Question")
                }
                .primaryButtonStyle(color: AppTheme.accentColor)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text("Select the matching Arabic letter above")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 20)
            }
        }
    }
    
    private var finishedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(viewModel.finalScore == 100 ? Color.green.opacity(0.12) : AppTheme.accentColor.opacity(0.12))
                    .frame(width: 140, height: 140)
                
                Image(systemName: viewModel.finalScore == 100 ? "trophy.fill" : "rosette")
                    .font(.system(size: 64))
                    .foregroundStyle(viewModel.finalScore == 100 ? Color.green : AppTheme.accentColor)
            }
            
            VStack(spacing: 8) {
                Text(viewModel.finalScore == 100 ? "Outstanding! Perfect 🏆" : "Challenge Completed!")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text("Your Score:")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                
                Text("\(viewModel.finalScore)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(viewModel.finalScore == 100 ? Color.green : AppTheme.accentColor)
                
                Text("Successfully answered \(viewModel.correctAnswersCount) out of \(viewModel.questionCount) questions correctly.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Button(action: {
                isPlayingChallenge = false
                viewModel.resetToSetup()
            }) {
                Label("Back to Challenge Menu", systemImage: "arrow.counterclockwise")
            }
            .primaryButtonStyle(color: AppTheme.accentColor)
            .padding(.horizontal)
            .padding(.bottom, 24)
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
}

#Preview {
    ChallengeScreen()
        .modelContainer(for: ChallengeHistory.self, inMemory: true)
}
