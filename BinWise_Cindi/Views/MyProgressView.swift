import SwiftUI
import Charts

/// Personal progress comparison — this week vs last week, best day ever, and the
/// user's longest sorting streak. No social/leaderboard data; everything here is
/// derived from the user's own ScanRecord history.
struct MyProgressView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.appLanguage) var language

    private let cal = Calendar.current

    // MARK: – Derived data

    private var thisWeekRecords: [ScanRecord] {
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())) ?? Date()
        return historyStore.records.filter { $0.date >= start }
    }

    private var lastWeekRecords: [ScanRecord] {
        let today = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: -7, to: today) ?? today
        let start = cal.date(byAdding: .day, value: -13, to: today) ?? today
        return historyStore.records.filter { $0.date >= start && $0.date < end }
    }

    private var thisWeekTotal: Int { thisWeekRecords.count }
    private var lastWeekTotal: Int { lastWeekRecords.count }
    private var thisWeekCO2: Double { thisWeekRecords.reduce(0) { $0 + $1.co2SavedKg } }
    private var lastWeekCO2: Double { lastWeekRecords.reduce(0) { $0 + $1.co2SavedKg } }

    private var bestDay: (date: Date, count: Int)? {
        let grouped = Dictionary(grouping: historyStore.records) { cal.startOfDay(for: $0.date) }
        guard let best = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        return (best.key, best.value.count)
    }

    private var currentStreak: Int { GamificationService.streak(from: historyStore.records) }

    private var longestStreakEver: Int {
        let days = Set(historyStore.records.map { cal.startOfDay(for: $0.date) }).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1, current = 1
        for i in 1..<days.count {
            if cal.dateComponents([.day], from: days[i - 1], to: days[i]).day == 1 {
                current += 1
                longest  = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    private struct WeekPoint: Identifiable {
        let id = UUID()
        let day: String
        let week: String
        let count: Int
    }

    private var comparisonSeries: [WeekPoint] {
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        let today   = cal.startOfDay(for: Date())
        var points: [WeekPoint] = []
        for i in 0..<7 {
            let day = cal.date(byAdding: .day, value: i - 6, to: today) ?? today
            let weekdayIdx = cal.component(.weekday, from: day) - 1
            let thisCount  = historyStore.records.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            let lastDay    = cal.date(byAdding: .day, value: -7, to: day) ?? day
            let lastCount  = historyStore.records.filter { cal.isDate($0.date, inSameDayAs: lastDay) }.count
            points.append(WeekPoint(day: symbols[weekdayIdx], week: thisWeekLabel, count: thisCount))
            points.append(WeekPoint(day: symbols[weekdayIdx], week: lastWeekLabel, count: lastCount))
        }
        return points
    }

    private var thisWeekLabel: String { language.text("This Week", "本周") }
    private var lastWeekLabel: String { language.text("Last Week", "上周") }

    // MARK: – Body

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    weekComparisonCard
                    dayByDayChart
                    bestDayCard
                    streakCard
                }
                .padding(DS.Spacing.md)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle(language.text("My Progress", "我的进度"))
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: – Week comparison

    private var trendIsUp: Bool { thisWeekTotal >= lastWeekTotal }
    private var trendDelta: Int { thisWeekTotal - lastWeekTotal }

    private var weekComparisonCard: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack {
                weekColumn(label: lastWeekLabel, items: lastWeekTotal, co2: lastWeekCO2, emphasized: false)
                Image(systemName: trendIsUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.title2.weight(.bold))
                    .foregroundColor(trendIsUp ? DS.statusSuccess : DS.statusError)
                weekColumn(label: thisWeekLabel, items: thisWeekTotal, co2: thisWeekCO2, emphasized: true)
            }

            Text(trendMessage)
                .font(.caption)
                .foregroundColor(DS.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    private var trendMessage: String {
        if lastWeekTotal == 0 && thisWeekTotal == 0 {
            return language.text("Start sorting to see your weekly trend.", "开始分类垃圾，查看每周趋势。")
        }
        if trendDelta > 0 {
            return language.text("You're sorting \(trendDelta) more item(s) than last week — keep it up! 🎉",
                                 "比上周多分类了\(trendDelta)件——继续保持！🎉")
        } else if trendDelta < 0 {
            return language.text("\(-trendDelta) fewer items than last week. You've got this!",
                                 "比上周少了\(-trendDelta)件，加油哦！")
        } else {
            return language.text("Same pace as last week — steady progress.", "与上周持平，稳步前进。")
        }
    }

    private func weekColumn(label: String, items: Int, co2: Double, emphasized: Bool) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(DS.textSecondary)
            Text("\(items)")
                .font(.system(size: emphasized ? 30 : 22, weight: .bold, design: .rounded))
                .foregroundColor(emphasized ? DS.brandAmberDeep : DS.textPrimary)
            Text(String(format: "%.2f kg CO₂", co2))
                .font(.caption2)
                .foregroundColor(DS.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Day-by-day grouped bar chart

    private var dayByDayChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            DS.sectionHeader(language.text("Day by Day", "每日对比"))
            Chart(comparisonSeries) { point in
                BarMark(
                    x: .value("Day", point.day),
                    y: .value("Items", point.count)
                )
                .position(by: .value("Week", point.week))
                .foregroundStyle(by: .value("Week", point.week))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                thisWeekLabel: DS.brandAmber,
                lastWeekLabel: DS.borderMedium,
            ])
            .chartLegend(position: .top, alignment: .leading)
            .chartXAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(DS.textSecondary) }
            }
            .chartYAxis(.hidden)
            .frame(height: 140)
            .padding(DS.Spacing.md)
            .cardStyle()
        }
    }

    // MARK: – Best day

    @ViewBuilder
    private var bestDayCard: some View {
        if let best = bestDay, best.count > 0 {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(DS.brandAmber)
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text("Your Best Day", "你的最佳记录"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DS.textSecondary)
                    Text(language.text(
                        "\(best.date.formatted(.dateTime.month(.wide).day())) — \(best.count) items sorted",
                        "\(best.date.formatted(.dateTime.month().day()))——分类了\(best.count)件"
                    ))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(DS.textPrimary)
                }
                Spacer()
            }
            .padding(DS.Spacing.md)
            .cardStyle()
        }
    }

    // MARK: – Streak

    private var streakCard: some View {
        HStack(spacing: DS.Spacing.lg) {
            streakColumn(value: currentStreak, label: language.text("Current Streak", "当前连续"), icon: "flame.fill", color: .orange)
            Divider().frame(height: 36)
            streakColumn(value: longestStreakEver, label: language.text("Longest Ever", "历史最长"), icon: "trophy.fill", color: DS.brandAmberDeep)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func streakColumn(value: Int, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value) \(language.text("days", "天"))")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(DS.textPrimary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(DS.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MyProgressView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MyProgressView()
                .environmentObject(HistoryStore())
        }
    }
}
