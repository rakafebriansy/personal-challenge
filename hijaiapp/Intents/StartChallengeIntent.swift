//
//  StartChallengeIntent.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 04/09/26.
//

import AppIntents
import SwiftUI

struct StartChallengeIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Challenge"
    static var description = IntentDescription("Open the Hijaiyah sound challenge screen for voice practice.")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppRouter.shared.selectedTab = .challenge
        
        return .result(dialog: "Opening Hijaiyah Challenge for you.")
    }
}
