import Foundation

/// Seeds realistic mock data on first launch so the app feels populated immediately
/// instead of showing all-zero charts and stats. Runs exactly once, gated by the
/// UserDefaults flag "hasSeededData".
@MainActor
enum StaticDataService {

    private static let seededKey = "hasSeededData"

    /// Seeds scan history and quiz stats if this is the first time the app has launched.
    /// Safe to call every app start — it's a no-op after the first run.
    static func seedIfNeeded(historyStore: HistoryStore, quizStore: QuizStore) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        seedHistory(into: historyStore)
        seedQuizStats(into: quizStore)
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    // MARK: – Scan history (last 30 days, ~45 records)

    private static let labels  = ["plastic", "paper", "cardboard", "metal",
                                   "glass", "food_waste", "battery", "other_trash"]
    private static let sources: [ScanRecord.ScanSource] = [.liveCamera, .photo, .barcode]

    private static func seedHistory(into store: HistoryStore) {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        var records: [ScanRecord] = []

        // Guarantee a 5-day current streak: one record on each of the last 5 days.
        for offset in 0..<5 {
            let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            records.append(makeRecord(date: date))
        }

        // Fill out the rest spread randomly across the last 30 days (~40 more records).
        for _ in 0..<40 {
            let offset       = Int.random(in: 0..<30)
            let baseDate     = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let randomSecond = TimeInterval(Int.random(in: 0..<86_400))
            records.append(makeRecord(date: baseDate.addingTimeInterval(randomSecond)))
        }

        for record in records.shuffled() {
            store.add(record)
        }
    }

    private static func makeRecord(date: Date) -> ScanRecord {
        let label      = labels.randomElement() ?? "plastic"
        let confidence = Double.random(in: 0.72...0.96)
        return ScanRecord(
            date:          date,
            objectLabel:   label,
            objectLabelCN: MappingService.chineseDisplayName(for: label),
            category:      MappingService.category(for: label),
            confidence:    confidence,
            co2SavedKg:    ImpactService.co2Saved(for: label),
            source:        sources.randomElement() ?? .photo
        )
    }

    // MARK: – Quiz stats

    private static func seedQuizStats(into store: QuizStore) {
        var stats = QuizStats()
        stats.totalAnswered = 24
        stats.totalCorrect  = 17
        stats.bestStreak    = 7
        stats.perCategoryMistakes = [
            WasteCategory.kitchen.rawValue:    4,
            WasteCategory.hazardous.rawValue:  2,
            WasteCategory.other.rawValue:      1,
            WasteCategory.recyclable.rawValue: 0,
        ]
        store.save(stats)
    }
}
