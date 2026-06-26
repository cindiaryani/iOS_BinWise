import SwiftUI

// MARK: – HistoryView

/// Scrollable list of saved ScanRecords with swipe-to-delete and tap-to-detail.
struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            Group {
                if historyStore.records.isEmpty {
                    emptyState
                } else {
                    recordList
                }
            }
        }
        .navigationTitle(language.text("History", "历史记录"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !historyStore.records.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        historyStore.clear()
                    } label: {
                        Text(language.text("Clear All", "清除全部"))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // MARK: – List

    private var recordList: some View {
        List {
            ForEach(historyStore.records) { record in
                NavigationLink {
                    HistoryDetailView(record: record)
                } label: {
                    recordRow(record)
                }
                .listRowBackground(DS.surface)
                .listRowSeparatorTint(DS.border)
            }
            .onDelete { offsets in historyStore.delete(at: offsets) }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
    }

    private func recordRow(_ record: ScanRecord) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: record.category.iconName)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(record.category.color)
                .cornerRadius(DS.Radius.control)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(record.displayLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DS.textPrimary)
                HStack(spacing: DS.Spacing.xs) {
                    Text(language.text(record.category.englishName, record.category.chineseName))
                        .font(.caption)
                        .foregroundColor(record.category.color)
                    Text("·")
                        .font(.caption)
                        .foregroundColor(DS.border)
                    Text(sourceLabel(record.source))
                        .font(.caption)
                        .foregroundColor(DS.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: DS.Spacing.xs) {
                Text(record.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(DS.textSecondary)
                Text(String(format: "%.0f%%", record.confidence * 100))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(confidenceColor(record.confidence))
            }
        }
        .padding(.vertical, DS.Spacing.xs)
    }

    private func sourceLabel(_ source: ScanRecord.ScanSource) -> String {
        switch source {
        case .liveCamera: return language.text("Live", "实时")
        case .photo:      return language.text("Photo", "照片")
        case .barcode:    return language.text("Barcode", "条码")
        case .quiz:       return language.text("Quiz", "测验")
        }
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        confidence >= 0.80 ? DS.success : confidence >= 0.60 ? Color.orange : .red
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 52))
                .foregroundColor(DS.border)
            Text(language.text("No records yet", "暂无记录"))
                .font(.headline)
                .foregroundColor(DS.textPrimary)
            Text(language.text("Scan some waste to build your history.",
                               "扫描垃圾后，记录将显示在这里。"))
                .font(.subheadline)
                .foregroundColor(DS.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DS.Spacing.xl)
    }
}

// MARK: – HistoryDetailView

/// Full detail screen for a single ScanRecord.
struct HistoryDetailView: View {
    let record: ScanRecord
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    categoryHeader
                    detailGrid
                    NavigationLink {
                        CategoryDemoView(initialCategory: record.category)
                    } label: {
                        Label(language.text("How to sort this →", "查看分类演示 →"),
                              systemImage: "play.rectangle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.md)
                            .background(record.category.color)
                            .cornerRadius(DS.Radius.control)
                    }
                }
                .padding(DS.Spacing.md)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle(record.displayLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var categoryHeader: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: record.category.iconName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(language.text(record.category.englishName, record.category.chineseName))
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                Text(record.objectLabelCN)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(record.category.color)
        .cornerRadius(DS.Radius.card)
    }

    private var detailGrid: some View {
        VStack(spacing: 0) {
            detailRow(
                icon: "calendar",
                label: language.text("Date", "日期"),
                value: record.date.formatted(.dateTime.year().month().day().hour().minute())
            )
            Divider().padding(.leading, 52)
            detailRow(
                icon: "percent",
                label: language.text("Confidence", "置信度"),
                value: String(format: "%.1f%%", record.confidence * 100),
                valueColor: confidenceColor(record.confidence)
            )
            Divider().padding(.leading, 52)
            detailRow(
                icon: "leaf.fill",
                label: language.text("CO₂ Saved", "碳减排"),
                value: String(format: "%.3f kg", record.co2SavedKg),
                valueColor: DS.success
            )
            Divider().padding(.leading, 52)
            detailRow(
                icon: sourceIcon(record.source),
                label: language.text("Source", "来源"),
                value: sourceName(record.source)
            )
        }
        .cardStyle()
    }

    private func detailRow(icon: String, label: String, value: String, valueColor: Color = DS.textPrimary) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(DS.primary)
                .frame(width: 28)
            Text(label)
                .font(.subheadline)
                .foregroundColor(DS.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm + DS.Spacing.xs)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        confidence >= 0.80 ? DS.success : confidence >= 0.60 ? Color.orange : .red
    }

    private func sourceIcon(_ source: ScanRecord.ScanSource) -> String {
        switch source {
        case .liveCamera: return "camera.viewfinder"
        case .photo:      return "photo"
        case .barcode:    return "barcode.viewfinder"
        case .quiz:       return "questionmark.square"
        }
    }

    private func sourceName(_ source: ScanRecord.ScanSource) -> String {
        switch source {
        case .liveCamera: return language.text("Live Camera", "实时扫描")
        case .photo:      return language.text("Photo", "照片")
        case .barcode:    return language.text("Barcode", "条形码")
        case .quiz:       return language.text("Quiz", "测验")
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HistoryView()
                .environmentObject(HistoryStore())
        }
    }
}
