//
//  AudioPlayerService.swift
//  hijaiapp
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import Foundation
import AVFoundation

@Observable
final class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    var isPlaying: Bool = false
    var playbackError: String? = nil
    
    func playRandomSound(for letter: String, variationCount: Int = 3) {
        let randomIndex = Int.random(in: 1...variationCount)
        let soundFileName = "\(letter.lowercased())_\(randomIndex)"
        
        playSound(named: soundFileName)
    }
    
    func playSound(named soundName: String) {
        stop()
        playbackError = nil
        
        guard let url = Bundle.main.url(forResource: soundName.lowercased(), withExtension: "wav") ??
                Bundle.main.url(forResource: soundName.lowercased(), withExtension: "mp3") else {
            let errorMsg = "Audio file '\(soundName)' not found in app bundle."
            print("[AudioPlayerService] \(errorMsg)")
            self.playbackError = errorMsg
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlaying = true
            playbackError = nil
        } catch {
            let errorMsg = "Failed to play audio: \(error.localizedDescription)"
            print("[AudioPlayerService] \(errorMsg)")
            self.playbackError = errorMsg
        }
    }
    
    func stop() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
        isPlaying = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
