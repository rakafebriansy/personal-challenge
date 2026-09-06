//
//  PermissionManager.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 05/09/26.
//

import SwiftUI
import AVFoundation

@Observable
final class PermissionManager {
    static let shared = PermissionManager()
    
    var isCameraAuthorized: Bool = false
    var isMicrophoneAuthorized: Bool = false
    var hasCheckedPermissions: Bool = false
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        isCameraAuthorized = (cameraStatus == .authorized)
        
        if #available(iOS 17.0, *) {
            isMicrophoneAuthorized = (AVAudioApplication.shared.recordPermission == .granted)
        } else {
            isMicrophoneAuthorized = (AVAudioSession.sharedInstance().recordPermission == .granted)
        }
        
        hasCheckedPermissions = true
    }
    
    func requestAllPermissions() async {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        if #available(iOS 17.0, *) {
            let micStatus = AVAudioApplication.shared.recordPermission
            if micStatus == .undetermined {
                _ = await AVAudioApplication.requestRecordPermission()
            }
        } else {
            let micStatus = AVAudioSession.sharedInstance().recordPermission
            if micStatus == .undetermined {
                await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { _ in
                        continuation.resume()
                    }
                }
            }
        }
        
        await MainActor.run {
            self.checkPermissions()
        }
    }
}
