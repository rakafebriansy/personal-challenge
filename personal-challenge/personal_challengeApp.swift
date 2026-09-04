//
//  personal_challengeApp.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 20/08/26.
//

import SwiftUI
import SwiftData

@main
struct personal_challengeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ChallengeHistory.self)
    }
}
