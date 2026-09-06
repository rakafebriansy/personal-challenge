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
    let container: ModelContainer?
    let initError: Error?
    
    init() {
        do {
            self.container = try ModelContainer(for: ChallengeHistory.self)
            self.initError = nil
        } catch {
            print("[personal_challengeApp] Failed to create persistent ModelContainer: \(error.localizedDescription)")
            do {
                let schema = Schema([ChallengeHistory.self])
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                self.container = try ModelContainer(for: schema, configurations: config)
                self.initError = nil
            } catch {
                self.container = nil
                self.initError = error
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if let container = container {
                ContentView()
                    .modelContainer(container)
            } else {
                AppErrorView(
                    title: "Database Initialization Failed",
                    message: "Unable to initialize the app's local data storage: \(initError?.localizedDescription ?? "Unknown error"). Please reinstall or restart the application.",
                    iconName: "externaldrive.badge.xmark",
                    iconColor: .red
                )
            }
        }
    }
}
