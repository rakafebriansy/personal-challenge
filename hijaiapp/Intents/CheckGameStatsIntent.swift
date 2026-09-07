//
//  CheckGameStatsIntent.swift
//  hijaiapp
//
//  Created by Raka Febrian Syahputra on 04/09/26.
//

import AppIntents
import SwiftData

struct CheckGameStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Game Statistics"
    static var description = IntentDescription("Check your challenge game statistics including total games played, best score, and lowest score.")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let container = try ModelContainer(for: ChallengeHistory.self)
            let descriptor = FetchDescriptor<ChallengeHistory>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let histories = try container.mainContext.fetch(descriptor)
            
            guard !histories.isEmpty else {
                return .result(dialog: "You haven't played any challenges yet. Start a challenge to record your statistics!")
            }
            
            let totalGames = histories.count
            
            guard let bestGame = histories.max(by: {
                a, b in
                if a.score != b.score {
                    return a.score < b.score
                }
                return a.totalQuestions < b.totalQuestions
            }) else {
                return .result(dialog: "No challenge statistics available.")
            }
            
            guard let worstGame = histories.min(by: { a, b in
                if a.score != b.score {
                    return a.score < b.score
                }
                return a.totalQuestions < b.totalQuestions
            }) else {
                return .result(dialog: "No challenge statistics available.")
            }
            
            let bestWrong = bestGame.totalQuestions - bestGame.correctAnswers
            let worstWrong = worstGame.totalQuestions - worstGame.correctAnswers
            
            let dialogResponse: String
            if totalGames == 1 {
                dialogResponse = "You have played 1 challenge so far. You got \(bestGame.correctAnswers) correct and \(bestWrong) wrong out of \(bestGame.totalQuestions) questions, with a score of \(bestGame.score)."
            } else {
                dialogResponse = "You have played \(totalGames) challenges. Your best game: \(bestGame.correctAnswers) correct and \(bestWrong) wrong out of \(bestGame.totalQuestions) questions (Score: \(bestGame.score)). Your lowest game: \(worstGame.correctAnswers) correct and \(worstWrong) wrong out of \(worstGame.totalQuestions) questions (Score: \(worstGame.score))."
            }
            
            return .result(dialog: IntentDialog(stringLiteral: dialogResponse))
        } catch {
            return .result(dialog: "Unable to retrieve your challenge statistics right now.")
        }
    }
}
