//
//  VoiceViewModel.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 02/09/26.
//

import Foundation
import AVFoundation

enum VoiceState: Equatable {
    case idle
    case countdown
    case recording
    case processing
    case correct
    case incorrect
    case error(String)
}

@Observable
class VoiceViewModel: NSObject {
    var voiceState: VoiceState = .idle
    var countdownValue: Int = 3
    var detectedLetter: HijaiyahLetter?
    var detectedRawLabel: String = ""
    var detectedConfidence: Double = 0.0
    var targetLetter: HijaiyahLetter?
    
    private let audioService = MLAudioService()
    private var countdownTimer: Timer?
    private var recordingTimer: Timer?
    
    private let recordingDuration: TimeInterval = 3.0
    
    override init() {
        super.init()
        audioService.delegate = self
    }
    
    func startSession(targetLetter: HijaiyahLetter) {
        self.targetLetter = targetLetter
        self.detectedLetter = nil
        self.detectedRawLabel = ""
        self.detectedConfidence = 0.0
        startCountdown()
    }
    
    func reset() {
        stopAllTimers()
        audioService.stopRecording()
        voiceState = .idle
        detectedLetter = nil
        detectedRawLabel = ""
        detectedConfidence = 0.0
        countdownValue = 3
        AppRouter.shared.isTabBarDisabled = false
    }
    
    private func startCountdown() {
        countdownValue = 3
        voiceState = .countdown
        AppRouter.shared.isTabBarDisabled = true
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] timer in
            guard let self else {
                return
            }
            
            if self.countdownValue > 1 {
                self.countdownValue -= 1
            } else {
                timer.invalidate()
                self.startRecording()
            }
        }
    }
    
    private func startRecording() {
        voiceState = .recording
        AppRouter.shared.isTabBarDisabled = true
        
        do {
            try audioService.startRecording()
        } catch {
            voiceState = .error("Failed to access microphone: \(error.localizedDescription)")
            AppRouter.shared.isTabBarDisabled = false
        }
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: recordingDuration, repeats: false) {
            [weak self] _ in
            self?.stopRecording()
        }
    }
    
    private func stopRecording() {
        recordingTimer?.invalidate()
        audioService.stopRecording()
        voiceState = .processing
        AppRouter.shared.isTabBarDisabled = true
        
        Task {
            @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            self?.evaluateResult()
        }
    }
    
    private func evaluateResult() {
        AppRouter.shared.isTabBarDisabled = false
        let parsed = detectedLetter ?? HijaiyahLetter.from(audioLabel: detectedRawLabel)
        self.detectedLetter = parsed
        
        guard let detected = parsed else {
            if detectedRawLabel.isEmpty {
                voiceState = .error("No sound detected. Please speak clearly into the microphone.")
            } else {
                voiceState = .incorrect
            }
            return
        }
        
        if let target = targetLetter, detected == target {
            voiceState = .correct
        } else {
            voiceState = .incorrect
        }
    }
    
    private func stopAllTimers() {
        countdownTimer?.invalidate()
        recordingTimer?.invalidate()
        countdownTimer = nil
        recordingTimer = nil
    }
    
    var confidenceText: String {
        return String(format: "%.0f%%", detectedConfidence * 100)
    }
    
    var detectedDisplayName: String {
        if let detected = detectedLetter {
            return detected.displayName
        } else if let parsed = HijaiyahLetter.from(audioLabel: detectedRawLabel) {
            return parsed.displayName
        }
        return detectedRawLabel.isEmpty ? "Unknown" : detectedRawLabel.capitalized
    }
}

extension VoiceViewModel: MLAudioServiceDelegate {
    func audioService(_ service: MLAudioService, didClassify result: String, confidence: Double) {
        if confidence > detectedConfidence {
            detectedRawLabel = result
            detectedLetter = HijaiyahLetter.from(audioLabel: result)
            detectedConfidence = confidence
        }
    }
    
    func audioService(_ service: MLAudioService, didEncounterError error: any Error) {
        stopAllTimers()
        voiceState = .error("Error while analyzing audio: \(error.localizedDescription)")
        AppRouter.shared.isTabBarDisabled = false
    }
}
