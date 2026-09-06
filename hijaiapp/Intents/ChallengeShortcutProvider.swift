//
//  ChallengeShortcutProvider.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 04/09/26.
//

import AppIntents

struct ChallengeShortcutProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartChallengeIntent(),
            phrases: [
                "Start practice in \(.applicationName)",
                "Practice challenge in \(.applicationName)",
                "Start challenge in \(.applicationName)",
                "Play challenge in \(.applicationName)"
            ],
            shortTitle: "Start Challenge",
            systemImageName: "play.circle.fill"
        )
        
        AppShortcut(
            intent: CheckGameStatsIntent(),
            phrases: [
                "Check my game stats in \(.applicationName)",
                "Check my challenge stats in \(.applicationName)",
                "How are my stats in \(.applicationName)",
                "What is my best score in \(.applicationName)"
            ],
            shortTitle: "Game Stats",
            systemImageName: "chart.bar.fill"
        )
    }
}
