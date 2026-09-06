//
//  MLAudioService.swift
//  hijaiapp
//
//  Created by Raka Febrian Syahputra on 01/09/26.
//

import Foundation
import AVFoundation
import SoundAnalysis

protocol MLAudioServiceDelegate: AnyObject {
    func audioService(_ service: MLAudioService, didClassify result: String, confidence: Double)
    func audioService(_ service: MLAudioService, didEncounterError error: Error)
}

class MLAudioService: NSObject {
    weak var delegate: MLAudioServiceDelegate?
    
    private let audioEngine = AVAudioEngine()
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private var classificationRequest: SNClassifySoundRequest?
    
    private var analysisTask: Task<Void, Never>?

    override init() {
        super.init()
        setupRequest()
    }
    
    private func setupRequest() {
        do {
            let config = MLModelConfiguration()
            let model = try HijaiyahSoundClassifier_4(configuration: config).model
            
            let soundClassifier = try SNClassifySoundRequest(mlModel: model)
            
            soundClassifier.windowDuration = CMTimeMakeWithSeconds(1.0, preferredTimescale: 44100)
            soundClassifier.overlapFactor = 0.5
            
            self.classificationRequest = soundClassifier
        } catch {
           print("MLAudioService: failed to setup request: \(error.localizedDescription)")
        }
    }
    
    func startRecording() throws {
        stopRecording()

        guard let request = classificationRequest else {
            throw NSError(domain: "MLAudioService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Classification request is not available"])
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        let newStreamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)

        try newStreamAnalyzer.add(request, withObserver: self)
        self.streamAnalyzer = newStreamAnalyzer
        
        let audioStream = AsyncStream<(AVAudioPCMBuffer, AVAudioTime)> {
            continuation in
            inputNode.installTap(onBus: 0, bufferSize: 8192, format: recordingFormat){
                buffer, time in
                continuation.yield((buffer, time))
            }
            
            continuation.onTermination = {
                @Sendable _ in
                inputNode.removeTap(onBus: 0)
            }
        }
        
        analysisTask = Task(priority: .userInitiated) {
            [weak self] in
            for await (buffer, time) in audioStream {
                guard !Task.isCancelled else {
                    break
                }
                self?.streamAnalyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopRecording() {
        analysisTask?.cancel()
        analysisTask = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        self.streamAnalyzer = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

extension MLAudioService: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult){
        guard let classificationResult = result as? SNClassificationResult else {
            return
        }
        
        guard let topClassification = classificationResult.classifications.first else {
            return
        }
        
        let label = topClassification.identifier
        let confidence = topClassification.confidence
        
        Task {
            @MainActor in
            self.delegate?.audioService(self, didClassify: label, confidence: confidence)
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        Task {
            @MainActor in
            self.delegate?.audioService(self, didEncounterError: error)
        }
    }
    
    func requestDidComplete(_ request: any SNRequest) {
        print("MLAudioService: analysis completed.")
    }
}
