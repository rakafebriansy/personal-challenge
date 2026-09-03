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
    var detectedLetter: String = ""
    var detectedConfidence: Double = 0.0
    var targetLetter: String = ""
    
    private let audioService = MLAudioService()
    private var countdownTimer: Timer?
    private var recordingTimer: Timer?
    
    private let recordingDuration: TimeInterval = 3.0
    
    override init() {
        super.init()
        audioService.delegate = self
    }
    
    func startSession(targetLetter: String) {
        self.targetLetter = targetLetter
        self.detectedLetter = ""
        self.detectedConfidence = 0.0
        startCountdown()
    }
    
    func reset() {
        stopAllTimers()
        audioService.stopRecording()
        voiceState = .idle
        detectedLetter = ""
        detectedConfidence = 0.0
        countdownValue = 3
    }
    
    private func startCountdown() {
        countdownValue = 3
        voiceState = .countdown
        
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
        
        do {
            try audioService.startRecording()
        } catch {
            voiceState = .error("Failed to access microphone: \(error.localizedDescription)")
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
        
        Task {
            @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            self?.evaluateResult()
        }
    }
    
    private func evaluateResult() {
        guard !detectedLetter.isEmpty else {
            voiceState = .error("No sound detected. Please try again.")
            return
        }
        
        if detectedLetter.lowercased() == targetLetter.lowercased() {
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
}

extension VoiceViewModel: MLAudioServiceDelegate {
    func audioService(_ service: MLAudioService, didClassify result: String, confidence: Double) {
        if confidence > detectedConfidence {
            detectedLetter = result
            detectedConfidence = confidence
        }
    }
    
    func audioService(_ service: MLAudioService, didEncounterError error: any Error) {
        stopAllTimers()
        voiceState = .error("Error while analyzing audio: \(error.localizedDescription)")
    }
}
