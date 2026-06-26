import Foundation

/// Persisted statistics from all quiz sessions — saved alongside sort_history.json.
struct QuizStats: Codable {
    /// Total questions answered correctly across all sessions.
    var totalCorrect: Int = 0
    /// Total questions answered (correct + wrong).
    var totalAnswered: Int = 0
    /// Highest consecutive-correct streak ever achieved.
    var bestStreak: Int = 0
    /// Mistake count per WasteCategory.rawValue — used by the Coach Agent.
    var perCategoryMistakes: [String: Int] = [:]
}
