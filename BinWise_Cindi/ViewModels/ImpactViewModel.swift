import SwiftUI

/// Aggregates sorting-history records into stats for ImpactView.
@MainActor
final class ImpactViewModel: ObservableObject {

    // MARK: – Published stats

    @Published private(set) var totalCO2Saved: Double = 0
    @Published private(set) var totalItems: Int = 0
    @Published private(set) var perCategoryCounts: [WasteCategory: Int] = [:]
    @Published private(set) var dailySeries: [DailyImpact] = []

    // MARK: – Types

    /// One point on the cumulative CO₂ timeline.
    struct DailyImpact: Identifiable {
        let id = UUID()
        let date: Date
        let cumulativeCO2: Double
    }

    // MARK: – Load

    /// Recomputes all stats from the provided record array.
    func load(from records: [ScanRecord]) {
        totalItems    = records.count
        totalCO2Saved = records.reduce(0) { $0 + $1.co2SavedKg }

        var counts: [WasteCategory: Int] = [:]
        for record in records { counts[record.category, default: 0] += 1 }
        perCategoryCounts = counts

        let sorted = records.sorted { $0.date < $1.date }
        var cumulative = 0.0
        dailySeries = sorted.map { record in
            cumulative += record.co2SavedKg
            return DailyImpact(date: record.date, cumulativeCO2: cumulative)
        }
    }
}
