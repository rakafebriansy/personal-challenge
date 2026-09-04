//
//  ChallengeViewModel.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 03/09/26.
//

import SwiftUI
import SwiftData

struct ChallengeQuestion {
    let targetLetter: String
    let targetArabic: String
    let options: [HijaiyahLetterOption]
}

struct HijaiyahLetterOption: Identifiable, Equatable {
    let id = UUID()
    let letter: String
    let arabic: String
}

enum ChallengeState {
    case setup
    case playing
    case finished
}

@Observable
final class ChallengeViewModel {
    var state: ChallengeState = .setup
    var questionCount: Int = 5
    
    var questions: [ChallengeQuestion] = []
    var currentQuestionIndex: Int = 0
    var correctAnswersCount: Int = 0
    
    var selectedOption: HijaiyahLetterOption? = nil
    var isAnswerEvaluated: Bool = false
    
    let audioPlayer = AudioPlayerService()
    
    let allLetters: [(letter: String, arabic: String)] = [
        ("alif", "ا"), ("ba", "ب"), ("ta", "ت"), ("tsa", "ث"),
        ("jim", "ج"), ("ha", "ح"), ("kha", "خ"), ("dal", "د"),
        ("dzal", "ذ"), ("ra", "ر"), ("zai", "ز"), ("sin", "س"),
        ("syin", "ش"), ("shad", "ص"), ("dhad", "ض"), ("tha", "ط"),
        ("zha", "ظ"), ("ain", "ع"), ("ghain", "غ"), ("fa", "ف"),
        ("qaf", "ق"), ("kaf", "ك"), ("lam", "ل"), ("mim", "م"),
        ("nun", "ن"), ("haa", "هـ"), ("waw", "و"), ("ya", "ي")
    ]
    
    var currentQuestion: ChallengeQuestion? {
        guard currentQuestionIndex < questions.count else {
            return nil
        }
        
        return questions[currentQuestionIndex]
    }
    
    var finalScore: Int {
        guard questionCount > 0 else {
            return 0
        }
        
        let rawScore = (Double(correctAnswersCount) / Double(questionCount)) * 100.0
        
        return Int(round(rawScore))
    }
    
    func startChallenge() {
        questionCount = min(max(questionCount, 3), 20)
        
        correctAnswersCount = 0
        currentQuestionIndex = 0
        selectedOption = nil
        isAnswerEvaluated = false
        
        generateQuestions()
        state = .playing
    }
    
    private func generateQuestions() {
        let shuffledTargets = allLetters.shuffled().prefix(questionCount)
        
        questions = shuffledTargets.map {
            target in
            let distractors = allLetters
                .filter {
                    $0.letter != target.letter
                }
                .shuffled()
                .prefix(3)
                .map {
                    HijaiyahLetterOption(letter: $0.letter, arabic: $0.arabic)
                }
            
            let correctOption = HijaiyahLetterOption(letter: target.letter, arabic: target.arabic)
            
            var options = distractors + [correctOption]
            options.shuffle()
            
            return ChallengeQuestion(targetLetter: target.letter, targetArabic: target.arabic, options: options)
        }
    }
    
    func playCurrentAudio() {
        guard let question = currentQuestion else {
            return
        }
        audioPlayer.playRandomSound(for: question.targetLetter)
    }
    
    func selectOption(_ option: HijaiyahLetterOption) {
        guard !isAnswerEvaluated, let question = currentQuestion else {
            return
        }
        
        selectedOption = option
        isAnswerEvaluated = true
        
        if option.letter == question.targetLetter {
            correctAnswersCount += 1
        }
    }
    
    func nextQuestion(modelContext: ModelContext) {
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            selectedOption = nil
            isAnswerEvaluated = false
            playCurrentAudio()
        } else {
            state = .finished
            saveToSwiftData(modelContext: modelContext)
        }
    }
    
    func resetToSetup() {
        audioPlayer.stop()
        state = .setup
        selectedOption = nil
        isAnswerEvaluated = false
        currentQuestionIndex = 0
    }
    
    private func saveToSwiftData(modelContext: ModelContext) {
        let history = ChallengeHistory(date: Date(), totalQuestions: questionCount, correctAnswers: correctAnswersCount, score: finalScore)
        modelContext.insert(history)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save quiz history to SwiftData: \(error.localizedDescription)")
        }
    }
}
