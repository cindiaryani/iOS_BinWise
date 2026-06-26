import Foundation

// MARK: – Time-range filter

/// Time range used to filter statistics data.
enum StatsRange: String, CaseIterable, Identifiable {
    case week  = "Week"
    case month = "Month"
    case all   = "All"

    var id: String { rawValue }

    var labelEN: String {
        switch self {
        case .week:  return "7 Days"
        case .month: return "30 Days"
        case .all:   return "All Time"
        }
    }

    var labelCN: String {
        switch self {
        case .week:  return "7天"
        case .month: return "30天"
        case .all:   return "全部"
        }
    }
}

// MARK: – Chart data points

/// One day's CO₂ contribution for the line/area chart.
struct DailyCO2Point: Identifiable {
    let id = UUID()
    let date: Date
    let kg: Double
}

/// One category bar for the waste-distribution chart.
struct CategoryCountPoint: Identifiable {
    let id: WasteCategory
    let category: WasteCategory
    let count: Int
    var label: String { category.englishName }
}

/// One category mistake count for the quiz-accuracy chart.
struct MistakePoint: Identifiable {
    let id: String
    let categoryRaw: String
    let count: Int
}

// MARK: – ViewModel

/// Aggregates scan-history and quiz data into statistics for StatisticsView.
/// Recomputes whenever `range` changes or `load` is called.
@MainActor
final class StatisticsViewModel: ObservableObject {

    // MARK: – Range picker

    @Published var range: StatsRange = .week {
        didSet { recompute() }
    }

    // MARK: – Published stats

    @Published private(set) var dailyCO2Points: [DailyCO2Point] = []
    @Published private(set) var categoryPoints: [CategoryCountPoint] = []
    @Published private(set) var totalItems: Int = 0
    @Published private(set) var totalCO2: Double = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var topCategory: WasteCategory? = nil
    @Published private(set) var busiestDayLabel: String = ""
    @Published private(set) var quizAccuracy: Double = 0
    @Published private(set) var quizTotalAnswered: Int = 0
    @Published private(set) var mistakePoints: [MistakePoint] = []

    // MARK: – Private cache

    private var allRecords: [ScanRecord] = []
    private var quizStats: QuizStats = QuizStats()

    // MARK: – Public

    /// Call from the view's onAppear and whenever the store changes.
    func load(records: [ScanRecord], quizStats: QuizStats) {
        self.allRecords = records
        self.quizStats  = quizStats
        recompute()
    }

    // MARK: – Private

    private func recompute() {
        let filtered = filter(allRecords)

        totalItems = filtered.count
        totalCO2   = filtered.reduce(0) { $0 + $1.co2SavedKg }

        // Category distribution
        let counts = Dictionary(grouping: filtered, by: \.category).mapValues(\.count)
        categoryPoints = WasteCategory.allCases.map {
            CategoryCountPoint(id: $0, category: $0, count: counts[$0] ?? 0)
        }
        topCategory = counts.max(by: { $0.value < $1.value })?.key

        // Daily CO₂ series — group by calendar day, sorted ascending
        let cal = Calendar.current
        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        dailyCO2Points = grouped
            .map { DailyCO2Point(date: $0.key, kg: $0.value.reduce(0) { $0 + $1.co2SavedKg }) }
            .sorted { $0.date < $1.date }

        // Busiest day
        if let busiest = grouped.max(by: { $0.value.count < $1.value.count })?.key {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            busiestDayLabel = formatter.string(from: busiest)
        } else {
            busiestDayLabel = ""
        }

        // Streaks (computed from all records, not just filtered)
        currentStreak = GamificationService.streak(from: allRecords)
        bestStreak    = quizStats.bestStreak

        // Quiz
        quizTotalAnswered = quizStats.totalAnswered
        let acc = quizStats.totalAnswered > 0
            ? Double(quizStats.totalCorrect) / Double(quizStats.totalAnswered)
            : 0
        quizAccuracy = acc

        mistakePoints = quizStats.perCategoryMistakes
            .map { MistakePoint(id: $0.key, categoryRaw: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func filter(_ records: [ScanRecord]) -> [ScanRecord] {
        guard range != .all else { return records }
        let days  = range == .week ? -7 : -30
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return records.filter { $0.date >= cutoff }
    }
}
