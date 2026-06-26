import SwiftUI

// MARK: – Phase

/// Controls which UI state QuizView renders.
enum QuizPhase: Equatable {
    case question
    case feedback(correct: Bool)
}

// MARK: – ViewModel

/// Drives the quiz flow: serves questions, validates answers, tracks score + streak.
/// Uses all 60 items from WasteKnowledgeBase, with optional Tricky-Only mode.
/// Call `configure(with:)` from QuizView.onAppear to inject the QuizStore.
@MainActor
final class QuizViewModel: ObservableObject {

    // MARK: – Published state (UI-bound)

    @Published private(set) var currentItem: QuizItem?
    @Published private(set) var phase: QuizPhase           = .question
    @Published private(set) var selectedCategory: WasteCategory? = nil
    /// Running score for this session.
    @Published private(set) var sessionScore: Int          = 0
    /// Current consecutive-correct streak.
    @Published private(set) var streak: Int                = 0
    /// All-time best streak (persisted).
    @Published private(set) var bestStreak: Int            = 0
    /// All-time totals (persisted).
    @Published private(set) var totalCorrect: Int          = 0
    @Published private(set) var totalAnswered: Int         = 0
    /// When true, only tricky-case items are served.
    @Published var trickyOnlyMode: Bool                    = false {
        didSet { restartDeck() }
    }

    // MARK: – Private

    private var remainingItems: [QuizItem] = []
    private weak var quizStore: QuizStore?

    // MARK: – Item bank (derived from WasteKnowledgeBase)

    /// Converts the full 60-item knowledge base into QuizItems.
    private var fullBank: [QuizItem] {
        WasteKnowledgeBase.items.map { item in
            QuizItem(
                name:            item.nameEN,
                chineseName:     item.nameCN,
                correctCategory: item.category,
                explanation:     "\(item.explanation)  /  \(item.tips)"
            )
        }
    }

    private var trickyBank: [QuizItem] {
        WasteKnowledgeBase.items.filter(\.isTricky).map { item in
            QuizItem(
                name:            item.nameEN,
                chineseName:     item.nameCN,
                correctCategory: item.category,
                explanation:     "\(item.explanation)  /  \(item.tips)"
            )
        }
    }

    private var activeBank: [QuizItem] { trickyOnlyMode ? trickyBank : fullBank }

    // MARK: – Injection (called from onAppear)

    /// Injects the QuizStore and starts the first question.
    func configure(with store: QuizStore) {
        guard quizStore == nil else { return }
        quizStore = store
        loadStats(from: store.stats)
        nextQuestion()
    }

    // MARK: – Public actions

    /// Records the user's answer and transitions to the feedback phase.
    func answer(_ category: WasteCategory) {
        guard let item = currentItem, phase == .question else { return }
        selectedCategory = category
        let correct = (category == item.correctCategory)
        totalAnswered += 1
        if correct {
            totalCorrect += 1
            sessionScore += 1
            streak       += 1
            bestStreak    = max(bestStreak, streak)
        } else {
            streak = 0
        }
        phase = .feedback(correct: correct)
        persist(mistakeCategory: correct ? nil : item.correctCategory)
    }

    /// Advances to the next question.
    func nextQuestion() {
        if remainingItems.isEmpty {
            remainingItems = activeBank.shuffled()
        }
        currentItem      = remainingItems.removeFirst()
        selectedCategory = nil
        phase            = .question
    }

    // MARK: – Private helpers

    /// Shuffles a fresh deck from the active bank (called when mode toggles).
    private func restartDeck() {
        remainingItems = activeBank.shuffled()
        currentItem    = remainingItems.removeFirst()
        selectedCategory = nil
        phase          = .question
    }

    private func loadStats(from s: QuizStats) {
        totalCorrect  = s.totalCorrect
        totalAnswered = s.totalAnswered
        bestStreak    = s.bestStreak
    }

    private func persist(mistakeCategory: WasteCategory?) {
        guard let store = quizStore else { return }
        var s = store.stats
        s.totalCorrect  = totalCorrect
        s.totalAnswered = totalAnswered
        s.bestStreak    = bestStreak
        if let cat = mistakeCategory {
            s.perCategoryMistakes[cat.rawValue, default: 0] += 1
        }
        store.save(s)
    }
}
