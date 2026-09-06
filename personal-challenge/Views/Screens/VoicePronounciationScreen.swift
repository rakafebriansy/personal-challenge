//
//  VoicePronounciationScreen.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import SwiftUI

struct VoicePronunciationScreen: View {
    @State private var viewModel = VoiceViewModel()
    @State private var selectedIndex: Int = 0
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let letters = HijaiyahLetter.allCases
    
    var currentLetter: HijaiyahLetter {
        letters[selectedIndex]
    }
    
    init(targetLetter: String = "alif", targetArabic: String = "ا") {
        if let idx = HijaiyahLetter.allCases.firstIndex(where: { $0.rawValue == targetLetter }) {
            _selectedIndex = State(initialValue: idx)
        } else {
            _selectedIndex = State(initialValue: 0)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                letterNavigationCard
                visualizerCard
                actionButton
                instructionsCard
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 8)
            .background(AppTheme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Voice Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ThemeMenuButton()
                        .disabled(isActionDisabled)
                        .accessibilityLabel("Appearance Settings")
                }
            }
        }
        .onChange(of: viewModel.voiceState) { _, newState in
            let isBusy = (newState == .countdown || newState == .recording || newState == .processing)
            AppRouter.shared.isTabBarDisabled = isBusy
            
            switch newState {
            case .countdown:
                AccessibilityNotificationHelper.postAnnouncement("Get ready to pronounce \(currentLetter.displayName)")
            case .recording:
                AccessibilityNotificationHelper.postAnnouncement("Recording active. Pronounce \(currentLetter.displayName) now.")
            case .processing:
                AccessibilityNotificationHelper.postAnnouncement("Analyzing your pronunciation.")
            case .correct:
                AccessibilityNotificationHelper.postAnnouncement("Correct! Pronunciation matched \(currentLetter.displayName).")
            case .incorrect:
                AccessibilityNotificationHelper.postAnnouncement("Sound mismatch. Detected \(viewModel.detectedDisplayName). Try again.")
            case .error(let msg):
                AccessibilityNotificationHelper.postAnnouncement("Error: \(msg)")
            default:
                break
            }
        }
        .onAppear {
            let isBusy = (viewModel.voiceState == .countdown || viewModel.voiceState == .recording || viewModel.voiceState == .processing)
            AppRouter.shared.isTabBarDisabled = isBusy
        }
        .onDisappear {
            viewModel.reset()
            AppRouter.shared.isTabBarDisabled = false
        }
    }
    
    private var letterNavigationCard: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                Button(action: {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = index
                        viewModel.reset()
                    }
                }) {
                    VStack(spacing: 1) {
                        Text(letter.arabic)
                            .font(.system(.body, design: .rounded).weight(.bold))
                        Text(letter.rawValue.capitalized)
                            .font(.system(.caption2, design: .rounded).weight(.medium))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(selectedIndex == index ? AppTheme.accentColor : Color(UIColor.tertiarySystemGroupedBackground))
                    .foregroundStyle(selectedIndex == index ? .white : AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                selectedIndex == index ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)),
                                lineWidth: 0.5
                            )
                    )
                }
                .disabled(isActionDisabled)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(letter.rawValue.capitalized), Arabic letter \(letter.arabic)")
                .accessibilityHint(selectedIndex == index ? "Currently selected" : "Double tap to practice this letter")
                .accessibilityAddTraits(selectedIndex == index ? [.isButton, .isSelected] : .isButton)
            }
        }
        .opacity(isActionDisabled ? 0.6 : 1.0)
        .allowsHitTesting(!isActionDisabled)
        .cardStyle()
    }
    
    private var visualizerCard: some View {
        VStack(spacing: 6) {
            HStack {
                Button(action: {
                    if selectedIndex > 0 {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedIndex -= 1
                            viewModel.reset()
                        }
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title3)
                        .foregroundStyle(selectedIndex > 0 && !isActionDisabled ? AppTheme.accentColor : Color.gray.opacity(0.3))
                }
                .disabled(selectedIndex == 0 || isActionDisabled)
                .accessibilityLabel("Previous letter")
                .accessibilityHint("Double tap to switch to previous Hijaiyah letter")
                
                Spacer()
                
                VStack(spacing: 0) {
                    Text(currentLetter.arabic)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    Text(currentLetter.rawValue.capitalized)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current letter: \(currentLetter.rawValue.capitalized), Arabic \(currentLetter.arabic)")
                
                Spacer()
                
                Button(action: {
                    if selectedIndex < letters.count - 1 {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedIndex += 1
                            viewModel.reset()
                        }
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(selectedIndex < letters.count - 1 && !isActionDisabled ? AppTheme.accentColor : Color.gray.opacity(0.3))
                }
                .disabled(selectedIndex >= letters.count - 1 || isActionDisabled)
                .accessibilityLabel("Next letter")
                .accessibilityHint("Double tap to switch to next Hijaiyah letter")
            }
            .padding(.horizontal, 4)
            
            Divider()
                .padding(.vertical, 6)
            
            visualizerView
                .frame(height: 70)
                .accessibilityElement(children: .combine)
        }
        .allowsHitTesting(!isActionDisabled)
        .cardStyle()
    }
    
    private var actionButton: some View {
        Button(action: {
            viewModel.startSession(targetLetter: currentLetter)
        }) {
            HStack(spacing: 6) {
                switch viewModel.voiceState {
                case .idle:
                    Label("Start Recording", systemImage: "mic.fill")
                case .countdown:
                    Label("Get Ready... (\(viewModel.countdownValue))", systemImage: "hourglass")
                case .recording:
                    Label("Recording Audio...", systemImage: "waveform")
                case .processing:
                    Label("Analyzing...", systemImage: "sparkles")
                case .correct, .incorrect, .error:
                    Label("Record Again", systemImage: "arrow.clockwise")
                }
            }
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isActionDisabled ? (colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray4)) : AppTheme.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .disabled(isActionDisabled)
        .accessibilityLabel(actionButtonAccessibilityLabel)
        .accessibilityHint(actionButtonAccessibilityHint)
    }
    
    private var actionButtonAccessibilityLabel: String {
        switch viewModel.voiceState {
        case .idle:
            return "Start Recording for \(currentLetter.displayName)"
        case .countdown:
            return "Get ready, starting in \(viewModel.countdownValue) seconds"
        case .recording:
            return "Recording audio in progress"
        case .processing:
            return "Analyzing pronunciation in progress"
        case .correct, .incorrect, .error:
            return "Record Again for \(currentLetter.displayName)"
        }
    }
    
    private var actionButtonAccessibilityHint: String {
        switch viewModel.voiceState {
        case .idle, .correct, .incorrect, .error:
            return "Double tap to start recording pronunciation"
        default:
            return "Recording is currently active"
        }
    }
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isShowingResult ? "Evaluation Results" : "Instructions")
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
            
            Group {
                switch viewModel.voiceState {
                case .idle:
                    Text("Tap 'Start Recording', wait for the countdown, then pronounce the letter '\(currentLetter.displayName)' clearly.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                case .countdown:
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                        Text("Get ready... Recording '\(currentLetter.rawValue.capitalized)' starts in \(viewModel.countdownValue)s.")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    
                case .recording:
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Microphone active. Pronounce '\(currentLetter.displayName)' now!")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.red)
                    }
                    
                case .processing:
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Model is evaluating your pronunciation...")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                case .correct:
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(Color.green)
                            Text("Mumtaz! Correct Pronunciation (\(viewModel.confidenceText))")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.green)
                        }
                        Text("Maa syaa Allah, your pronunciation accurately matches \(currentLetter.displayName)!")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    
                case .incorrect:
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(Color.orange)
                            Text("Sound Mismatch — Try Again")
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.orange)
                        }
                        Text("AI detected \(viewModel.detectedDisplayName) (\(viewModel.confidenceText) confidence), but expected \(currentLetter.displayName).")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                case .error(let message):
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.red)
                        Text(message)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if isShowingResult {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .cardStyle()
    }
    
    private var isActionDisabled: Bool {
        viewModel.voiceState == .countdown ||
        viewModel.voiceState == .recording ||
        viewModel.voiceState == .processing
    }
    
    private var isShowingResult: Bool {
        switch viewModel.voiceState {
        case .correct, .incorrect:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    private var visualizerView: some View {
        switch viewModel.voiceState {
        case .idle:
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(width: 60, height: 60)
                
                Text("Ready to listen")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
        case .countdown:
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 46, height: 46)
                    
                    Text("\(viewModel.countdownValue)")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.orange)
                }
                .frame(width: 60, height: 60)
                
                Text("Get ready to speak...")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(Color.orange)
            }
            
        case .incorrect:
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.orange)
                }
                .frame(width: 60, height: 60)
                
                Text("Try pronouncing '\(currentLetter.rawValue.capitalized)' again")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(Color.orange)
            }
            
        case .recording:
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .fill(Color.red.opacity(0.25))
                        .frame(width: 52, height: 52)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "mic.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(width: 60, height: 60)
                
                Text("Listening...")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.red)
            }
            
        case .processing:
            VStack(spacing: 6) {
                ProgressView()
                    .controlSize(.regular)
                Text("Analyzing audio...")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
        case .correct:
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.green)
                Text("Mumtaz! (ممتاز)")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.green)
            }
            
        case .error:
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.red)
                Text("Recording Failed")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }
}

#Preview("Light Mode") {
    VoicePronunciationScreen(targetLetter: "ba", targetArabic: "ب")
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VoicePronunciationScreen(targetLetter: "ba", targetArabic: "ب")
        .preferredColorScheme(.dark)
}
