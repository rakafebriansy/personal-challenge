//
//  ChallengeHistory.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import Foundation
import SwiftData

@Model
final class ChallengeHistory {
    var id: UUID = UUID()
    var date: Date = Date()
    var totalQuestions: Int = 5
    var correctAnswers: Int = 5
    var score: Int = 100
    
    init(date: Date, totalQuestions: Int, correctAnswers: Int, score: Int) {
        self.date = date
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.score = score
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var isPerfectScore: Bool {
        return score == 100
    }
    
    var badgeTitle: String {
        switch score {
        case 100:
            return "Mumtaz! (Perfect) 🏆"
        case 80..<100:
            return "Jayyid Jiddan (Very Good) 🌟"
        case 60..<80:
            return "Jayyid (Good) 👍"
        default:
            return "Need more practice 📚"
        }
    }
}
