import SwiftUI
import Charts

/// Full-screen statistics dashboard. Reachable from ProfileView → Statistics.
struct StatisticsView: View {

    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var quizStore:    QuizStore
    @StateObject private var vm = StatisticsViewModel()
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    rangePicker
                    statTilesRow
                    co2Chart
                    categoryChart
                    quizSection
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle(language.text("Statistics", "数据统计"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { reload() }
        .onChange(of: historyStore.records.count) { _ in reload() }
        .onChange(of: vm.range) { _ in reload() }
    }

    private func reload() {
        vm.load(records: historyStore.records, quizStats: quizStore.stats)
    }

    // MARK: – Range picker

    private var rangePicker: some View {
        Picker("", selection: $vm.range) {
            ForEach(StatsRange.allCases) { r in
                Text(language.text(r.labelEN, r.labelCN)).tag(r)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: – Stat tiles

    private var statTilesRow: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: DS.Spacing.sm) {
            statTile(value: "\(vm.totalItems)",
                     label: language.text("Items Sorted", "已分类"),
                     icon: "checkmark.circle.fill", color: DS.success)
            statTile(value: String(format: "%.2f kg", vm.totalCO2),
                     label: language.text("CO₂ Saved", "碳减排"),
                     icon: "leaf.fill", color: DS.primary)
            statTile(value: "\(vm.currentStreak)",
                     label: language.text("Current Streak", "当前连续"),
                     icon: "flame.fill", color: .orange)
            statTile(value: vm.topCategory.map { language.text($0.englishName, $0.chineseName) } ?? "—",
                     label: language.text("Top Category", "最多分类"),
                     icon: "trophy.fill", color: .yellow)
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(DS.textSecondary)
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    // MARK: – CO₂ chart

    private var co2Chart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("CO₂ Saved Over Time", "碳减排趋势"),
                  systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textPrimary)

            if vm.dailyCO2Points.isEmpty {
                emptyState(language.text("Sort some waste to see your CO₂ trend.",
                                         "开始分类垃圾后，将显示碳减排趋势。"))
            } else {
                Chart(vm.dailyCO2Points) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("kg", point.kg)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DS.primary.opacity(0.35), DS.primary.opacity(0.04)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("kg", point.kg)
                    )
                    .foregroundStyle(DS.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .symbol(.circle)
                    .symbolSize(28)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(DS.textSecondary)
                        AxisGridLine(stroke: StrokeStyle(dash: [4, 4]))
                            .foregroundStyle(DS.border)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisValueLabel()
                            .foregroundStyle(DS.textSecondary)
                        AxisGridLine(stroke: StrokeStyle(dash: [4, 4]))
                            .foregroundStyle(DS.border)
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    // MARK: – Category chart

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Waste by Category", "各类垃圾统计"),
                  systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textPrimary)

            let hasData = vm.categoryPoints.contains { $0.count > 0 }
            if !hasData {
                emptyState(language.text("No category data yet.", "暂无分类数据。"))
            } else {
                Chart(vm.categoryPoints) { point in
                    BarMark(
                        x: .value("Category", language.text(point.category.englishName,
                                                             point.category.chineseName)),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(point.category.color)
                    .cornerRadius(6)
                    .annotation(position: .top, alignment: .center) {
                        if point.count > 0 {
                            Text("\(point.count)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(point.category.color)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks {
                        AxisValueLabel()
                            .foregroundStyle(DS.textSecondary)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 150)
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    // MARK: – Quiz section

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Label(language.text("Quiz Accuracy", "测验准确率"),
                  systemImage: "brain.head.profile")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textPrimary)

            if vm.quizTotalAnswered == 0 {
                emptyState(language.text("Complete some quiz questions to see your accuracy.",
                                         "完成测验后，将显示准确率统计。"))
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    // Accuracy gauge row
                    HStack {
                        Text(language.text("Overall Accuracy", "总体准确率"))
                            .font(.subheadline)
                            .foregroundColor(DS.textPrimary)
                        Spacer()
                        Text("\(Int(vm.quizAccuracy * 100))%  (\(vm.quizTotalAnswered) \(language.text("answered", "题")))")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(accuracyColor(vm.quizAccuracy))
                    }
                    ProgressView(value: vm.quizAccuracy)
                        .tint(accuracyColor(vm.quizAccuracy))

                    if !vm.mistakePoints.isEmpty {
                        Divider().padding(.top, DS.Spacing.xs)
                        Text(language.text("Most mistakes by category:", "各类别最多错误："))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(DS.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(vm.mistakePoints.prefix(4)) { point in
                            let cat = WasteCategory(rawValue: point.categoryRaw)
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: cat?.iconName ?? "questionmark.circle")
                                    .font(.caption)
                                    .foregroundColor(cat?.color ?? DS.border)
                                    .frame(width: 20)
                                Text(cat.map { language.text($0.englishName, $0.chineseName) }
                                     ?? point.categoryRaw)
                                    .font(.caption)
                                    .foregroundColor(DS.textPrimary)
                                Spacer()
                                Text("\(point.count) \(language.text("mistake(s)", "次错误"))")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        accuracy >= 0.80 ? DS.success : accuracy >= 0.60 ? Color.orange : .red
    }

    // MARK: – Shared empty state

    private func emptyState(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .foregroundColor(DS.border)
            Text(message)
                .font(.caption)
                .foregroundColor(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, DS.Spacing.sm)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StatisticsView()
                .environmentObject(HistoryStore())
                .environmentObject(QuizStore())
        }
    }
}
