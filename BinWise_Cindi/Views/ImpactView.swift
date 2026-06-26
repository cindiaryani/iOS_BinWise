import SwiftUI
import Charts

/// Displays the user's cumulative environmental impact using Swift Charts.
struct ImpactView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @StateObject private var vm = ImpactViewModel()
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            Group {
                if historyStore.records.isEmpty {
                    emptyState
                } else {
                    contentScroll
                }
            }
        }
        .navigationTitle(language.text("My Impact", "我的贡献"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.load(from: historyStore.records) }
        .onChange(of: historyStore.records.count) { _ in
            vm.load(from: historyStore.records)
        }
    }

    // MARK: – Scroll content

    private var contentScroll: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                heroCard
                if vm.dailySeries.count >= 2 {
                    co2LineChart
                }
                categoryBarChart
            }
            .padding(DS.Spacing.md)
            .padding(.bottom, 90)
        }
    }

    // MARK: – Hero card

    private var heroCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(String(format: "%.2f kg", vm.totalCO2Saved))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(DS.success)
                Label(language.text("CO₂ Saved", "碳减排"), systemImage: "leaf.fill")
                    .font(.subheadline)
                    .foregroundColor(DS.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: DS.Spacing.xs) {
                Text("\(vm.totalItems)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                Label(language.text("Items Sorted", "已分类"), systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(DS.textSecondary)
            }
        }
        .padding(DS.Spacing.lg)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – CO₂ area + line chart

    private var co2LineChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Cumulative CO₂ Saved", "累积碳减排"),
                  systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textPrimary)

            Chart(vm.dailySeries) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("kg", point.cumulativeCO2)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [DS.success.opacity(0.35), DS.success.opacity(0.04)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("kg", point.cumulativeCO2)
                )
                .foregroundStyle(DS.success)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .symbol(.circle)
                .symbolSize(30)
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
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – Category bar chart

    private var categoryBarChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Items by Category", "分类统计"), systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textPrimary)

            Chart(WasteCategory.allCases, id: \.self) { cat in
                let count = vm.perCategoryCounts[cat] ?? 0
                BarMark(
                    x: .value("Category", language.text(cat.englishName, cat.chineseName)),
                    y: .value("Count", count)
                )
                .foregroundStyle(cat.color)
                .cornerRadius(6)
                .annotation(position: .top, alignment: .center) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(cat.color)
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
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 64))
                .foregroundColor(DS.border)
            Text(language.text("No impact yet", "暂无贡献数据"))
                .font(.title3.weight(.semibold))
                .foregroundColor(DS.textPrimary)
            Text(language.text(
                "Sort some waste to see your CO₂ savings here.",
                "开始分类垃圾，查看你的碳减排贡献。"
            ))
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .foregroundColor(DS.textSecondary)
        }
        .padding(DS.Spacing.xxl)
    }
}

struct ImpactView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ImpactView()
                .environmentObject(HistoryStore())
        }
    }
}
