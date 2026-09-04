//
//  AudioPlayerService.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import Foundation
import AVFoundation

@Observable
final class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    var isPlaying: Bool = false
    
    func playRandomSound(for letter: String, variationCount: Int = 3) {
        let randomIndex = Int.random(in: 1...variationCount)
        let soundFileName = "\(letter.lowercased())_\(randomIndex)"
        
        playSound(named: soundFileName)
    }
    
    func playSound(named soundName: String) {
        stop()
        
        guard let url = Bundle.main.url(forResource: soundName.lowercased(), withExtension: "wav") ??
                Bundle.main.url(forResource: soundName.lowercased(), withExtension: "mp3") else {
            print("Audio file '\(soundName)' is not found in app bundle.")
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
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
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
