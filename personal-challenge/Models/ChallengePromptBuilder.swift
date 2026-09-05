//
//  ChallengePromptBuilder.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 05/09/26.
//

import Foundation

struct ChallengePromptBuilder {
    static func buildEvaluationPrompt(from history: [ChallengeHistory]) -> String {
        guard !history.isEmpty else {
            return buildDefaultPrompt()
        }
        
        let totalSessions = history.count
        let averageScore = history.reduce(0) { 
            $0 + $1.score 
        } / totalSessions
        
        let allMissed = history.flatMap { $0.missedLetters }
        let focusLetters = Array(Set(allMissed)).prefix(3).joined(separator: ", ")
        let recommendationText = focusLetters.isEmpty ? "all Hijaiyah sounds" : focusLetters
        
        let performanceGrade: String
        if averageScore >= 90 {
            performanceGrade = "Excellent (Mumtaz)"
        } else if averageScore >= 75 {
            performanceGrade = "Good (Jayyid)"
        } else {
            performanceGrade = "Needs Practice"
        }
        
        return """
<|im_start|>system
You are a warm Islamic Hijaiyah tutor. Write a concise 2-sentence feedback for the student.
<|im_end|>
<|im_start|>user
Grade: Good (Jayyid)
Practice: dal, ra
<|im_end|>
<|im_start|>assistant
Barakallahu feek, great progress on your quiz! Continue practicing the sounds of dal and ra to master them with confidence.
<|im_end|>
<|im_start|>user
Grade: \(performanceGrade)
Practice: \(recommendationText)
<|im_end|>
<|im_start|>assistant
"""
    }
    
    private static func buildDefaultPrompt() -> String {
        return """
<|im_start|>system
You are a friendly Hijaiyah Quiz Tutor. Give a warm 2-sentence greeting welcoming the user to their first sound challenge quiz.
<|im_end|>
<|im_start|>user
I am ready to start my first Hijaiyah quiz session!
<|im_end|>
<|im_start|>assistant
Welcome to the Hijaiyah Listening Challenge! Listen carefully to each sound and select the matching Arabic letter.
<|im_end|>
"""
    }
}
