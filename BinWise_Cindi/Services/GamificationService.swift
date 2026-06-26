import Foundation

/// Stateless service that derives gamification state from HistoryStore + QuizStats.
/// All methods are pure functions — no mutable state, no dependencies to inject.
enum GamificationService {

    // MARK: – Daily streak

    /// Returns the number of consecutive calendar days (ending today) on which the user
    /// made at least one sort. Counts today if there is a record for it.
    static func streak(from records: [ScanRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days  = Set(records.map { cal.startOfDay(for: $0.date) })
                        .sorted(by: >)
        var streak   = 0
        var expected = today
        for day in days {
            if day == expected {
                streak  += 1
                expected = cal.date(byAdding: .day, value: -1, to: expected) ?? expected
            } else if day < expected {
                break
            }
        }
        return streak
    }

    // MARK: – Badges

    /// Computes the full badge set with unlock state for the current user.
    static func badges(from records: [ScanRecord], quizStats: QuizStats) -> [Badge] {
        let count = records.count
        let co2   = records.reduce(0) { $0 + $1.co2SavedKg }
        let days  = streak(from: records)

        return [
            Badge(id: "first_sort",
                  title: "First Sort  初次分类",
                  description: "Complete your first waste sort.",
                  icon: "star.fill",
                  unlocked: count >= 1),
            Badge(id: "getting_started",
                  title: "Getting Started  入门",
                  description: "Answer your first quiz question.",
                  icon: "flag.fill",
                  unlocked: quizStats.totalAnswered >= 1),
            Badge(id: "ten_items",
                  title: "10 Items  十件分类",
                  description: "Sort 10 items correctly.",
                  icon: "checkmark.seal.fill",
                  unlocked: count >= 10),
            Badge(id: "fifty_items",
                  title: "50 Items  五十件",
                  description: "Sort 50 items — great habit!",
                  icon: "medal.fill",
                  unlocked: count >= 50),
            Badge(id: "quiz_master",
                  title: "Quiz Master  答题达人",
                  description: "Answer 20 quiz questions correctly.",
                  icon: "brain.head.profile",
                  unlocked: quizStats.totalCorrect >= 20),
            Badge(id: "streak_7",
                  title: "7-Day Streak  七天连续",
                  description: "Use BinWise 7 days in a row.",
                  icon: "flame.fill",
                  unlocked: days >= 7),
            Badge(id: "eco_warrior",
                  title: "Eco Warrior  环保勇士",
                  description: "Cumulatively save 1 kg of CO₂.",
                  icon: "leaf.circle.fill",
                  unlocked: co2 >= 1.0),
        ]
    }
}
