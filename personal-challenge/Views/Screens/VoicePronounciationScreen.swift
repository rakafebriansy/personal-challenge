//
//  VoicePronounciationScreen.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import SwiftUI

struct VoicePronunciationScreen: View {
    @State private var viewModel = VoiceViewModel()
    
    let targetLetter: String
    let targetArabic: String
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1. Header
            HStack {
                Text("Latihan Pelafalan")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                
                if viewModel.voiceState != .idle {
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.accentColor)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(AppTheme.primaryBackground)
            
            // MARK: - 2. Fitur Utama (Kartu Huruf Target & Visualizer)
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(AppTheme.secondaryBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 16) {
                    // Huruf Target
                    VStack(spacing: 4) {
                        Text(targetArabic)
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        Text(targetLetter.capitalized)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.top, 8)
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    // Visualizer / Feedback Animasi
                    visualizerView
                        .frame(maxHeight: .infinity)
                }
                .padding()
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // MARK: - 3. Tombol Aksi
            Button(action: {
                viewModel.startSession(targetLetter: targetLetter)
            }) {
                HStack(spacing: 8) {
                    switch viewModel.voiceState {
                    case .idle:
                        Label("Mulai Rekam", systemImage: "mic.fill")
                    case .countdown:
                        Label("Bersiaplah... (\(viewModel.countdownValue))", systemImage: "hourglass")
                    case .recording:
                        Label("Merekam Suara...", systemImage: "waveform")
                    case .processing:
                        Label("Menganalisis...", systemImage: "sparkles")
                    case .correct, .incorrect, .error:
                        Label("Rekam Ulang", systemImage: "arrow.clockwise")
                    }
                }
            }
            .primaryButtonStyle(
                color: isActionDisabled ? Color(UIColor.systemGray4) : AppTheme.accentColor,
                isEnabled: !isActionDisabled
            )
            .disabled(isActionDisabled)
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // MARK: - 4. Section Instruksi dan Hasil (Bagian Bawah)
            VStack(alignment: .leading, spacing: 8) {
                Text(isShowingResult ? "Hasil Evaluasi" : "Instruksi")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                
                Group {
                    switch viewModel.voiceState {
                    case .idle:
                        Text("Tekan tombol 'Mulai Rekam', tunggu hitung mundur 3 detik, lalu ucapkan huruf '\(targetLetter.capitalized)' dengan lantang dan jelas.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                    case .countdown:
                        HStack(spacing: 8) {
                            Image(systemName: "hourglass")
                                .foregroundStyle(Color.orange)
                            Text("Bersiaplah... Rekaman dimulai dalam \(viewModel.countdownValue) detik.")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        
                    case .recording:
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                            Text("Mikrofon aktif. Ucapkan huruf '\(targetLetter.capitalized)' sekarang!")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color.red)
                        }
                        
                    case .processing:
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Model sedang mengevaluasi makhraj suara Anda...")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                    case .correct:
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.green)
                                Text("Pelafalan Tepat! (\(viewModel.confidenceText))")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            Text("Pengucapan Anda terdeteksi sesuai dengan huruf '\(targetLetter.capitalized)'.")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                    case .incorrect:
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .foregroundStyle(Color.orange)
                                Text("Ayo Coba Lagi (\(viewModel.confidenceText))")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                            Text("Terdeteksi mirip: '\(viewModel.detectedLetter.capitalized)'. Ucapkan kembali dengan lebih jelas.")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                    case .error(let message):
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.red)
                            Text(message)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
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
            .padding(.bottom, 20) // Jarak aman di atas Tab Bar
        }
        .background(AppTheme.primaryBackground.ignoresSafeArea())
        .onDisappear {
            viewModel.reset()
        }
    }
    
    // MARK: - Helper Computed Properties
    
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
    
    // MARK: - Visualizer Component
    
    @ViewBuilder
    private var visualizerView: some View {
        switch viewModel.voiceState {
        case .idle, .countdown, .incorrect:
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.1))
                        .frame(width: 90, height: 90)
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.accentColor)
                }
                Text("Siap mendengarkan")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
        case .recording:
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 80, height: 80)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                Text("Mendengarkan...")
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.red)
            }
            
        case .processing:
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.4)
                Text("Menganalisis audio...")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
        case .correct:
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.green)
                Text("Mumtaz! (Luar Biasa)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.green)
            }
            
        case .error:
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.red)
                Text("Gagal Merekam")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }
}

#Preview {
    VoicePronunciationScreen(targetLetter: "ba", targetArabic: "ب")
}
