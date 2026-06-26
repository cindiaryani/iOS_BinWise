import SwiftUI

// MARK: – Confidence badge

struct ConfidenceBadge: View {
    let confidence: Double

    private var badgeColor: Color {
        confidence >= 0.80 ? DS.success :
        confidence >= 0.60 ? Color.orange :
        .red
    }

    private var badgeLabel: String {
        confidence >= 0.80 ? "High confidence" :
        confidence >= 0.60 ? "Moderate confidence" :
        "Low confidence"
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Text("\(Int(confidence * 100))%")
                .font(.subheadline.weight(.bold))
                .foregroundColor(badgeColor)
            Text("·")
                .foregroundColor(DS.border)
            Text(badgeLabel)
                .font(.caption.weight(.medium))
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(badgeColor.opacity(0.10))
        .cornerRadius(DS.Radius.badge)
    }
}

// MARK: – ResultView

/// Displays the final classification result with bilingual disposal guidance,
/// safety advisories, and a link to the visual sorting demo.
struct ResultView: View {
    @ObservedObject var viewModel: ScanViewModel
    @EnvironmentObject var historyStore:  HistoryStore
    @EnvironmentObject var settingsStore: SettingsStore
    @StateObject private var speech = SpeechService()
    @State private var saved = false
    @State private var showAlternatives = false
    @Environment(\.appLanguage) var language

    private var resolvedCategory: WasteCategory? {
        guard let a = viewModel.assessment else { return nil }
        return WasteCategory(rawValue: a.category)
            ?? MappingService.category(for: viewModel.classificationResult?.label ?? "")
    }

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    imageThumbnail
                    if let result = viewModel.classificationResult, result.confidence < 0.50 {
                        uncertainBanner
                    } else if viewModel.lowConfidence {
                        lowConfidenceCard
                    } else {
                        categoryCard
                    }
                    safetySection
                    guidanceCard
                    alternativesSection
                    sortingDemoLink
                    saveButton
                }
                .padding(DS.Spacing.md)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle(language.text("Result", "结果"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.guidance) { text in
            guard let text, settingsStore.voiceEnabled else { return }
            speech.speak(text, language: settingsStore.language)
        }
        .onAppear {
            if let text = viewModel.guidance, settingsStore.voiceEnabled {
                speech.speak(text, language: settingsStore.language)
            }
        }
        .onDisappear { speech.stop() }
    }

    // MARK: – Image thumbnail

    private var imageThumbnail: some View {
        Group {
            if let img = viewModel.capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(DS.Radius.card)
                    .cardShadow()
            }
        }
    }

    // MARK: – Very-low-confidence banner (< 50%)

    private var uncertainBanner: some View {
        VStack(spacing: DS.Spacing.sm) {
            Label(language.text("Uncertain Result", "结果不确定"),
                  systemImage: "questionmark.circle.fill")
                .font(.headline.weight(.semibold))
                .foregroundColor(.orange)
            Text(language.text(
                "The model is not confident enough. Try scanning again with better lighting.",
                "模型置信度过低，请在光线充足的环境下重新扫描。"
            ))
            .font(.caption)
            .foregroundColor(DS.textSecondary)
            .multilineTextAlignment(.center)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.10))
        .cornerRadius(DS.Radius.card)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card)
            .stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: – Confident category card

    @ViewBuilder
    private var categoryCard: some View {
        if let cat = resolvedCategory, let result = viewModel.classificationResult {
            VStack(spacing: DS.Spacing.sm) {
                HStack {
                    Text(result.displayLabel)
                        .font(.title2.weight(.bold))
                        .foregroundColor(DS.textPrimary)
                    Spacer()
                    ConfidenceBadge(confidence: result.confidence)
                }
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: cat.iconName)
                    Text(language.text(cat.englishName, cat.chineseName))
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(cat.color)
                .cornerRadius(DS.Radius.badge)
            }
            .padding(DS.Spacing.md)
            .background(DS.surface)
            .cornerRadius(DS.Radius.card)
            .cardShadow()
        }
    }

    // MARK: – Low-confidence card (≥ 50% but < 70%)

    private var lowConfidenceCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Not sure — please verify", "请手动确认"),
                  systemImage: "questionmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.textSecondary)
            HStack(spacing: DS.Spacing.sm) {
                ForEach(Array(viewModel.candidates.enumerated()), id: \.offset) { _, candidate in
                    candidateChip(candidate)
                }
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private func candidateChip(_ candidate: ClassificationCandidate) -> some View {
        let cat = MappingService.category(for: candidate.label)
        return VStack(spacing: DS.Spacing.xs) {
            Text(candidate.displayLabel)
                .font(.caption.weight(.medium))
            Text(language.text(cat.englishName, cat.chineseName))
                .font(.caption2)
            Text("\(Int(candidate.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(DS.textSecondary)
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .background(cat.color.opacity(0.12))
        .foregroundColor(cat.color)
        .cornerRadius(DS.Radius.control)
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.control)
            .stroke(cat.color, lineWidth: 1))
    }

    // MARK: – Safety & Handling section

    @ViewBuilder
    private var safetySection: some View {
        if let advisory = viewModel.safetyAdvisory {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Label(language.text("Safety & Handling", "安全处理"),
                      systemImage: "shield.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(advisory.requiresSpecialDisposal ? .red : DS.primary)

                // Special disposal badge
                if advisory.requiresSpecialDisposal {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(language.text("Special disposal required",
                                           "需要专门回收处理"))
                            .font(.caption.weight(.bold))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Color.red.opacity(0.10))
                    .cornerRadius(DS.Radius.badge)
                }

                // Warnings (amber card)
                if !advisory.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        ForEach(advisory.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundColor(DS.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(DS.Spacing.sm)
                    .background(Color.orange.opacity(0.10))
                    .cornerRadius(DS.Radius.control)
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.control)
                        .stroke(Color.orange.opacity(0.30), lineWidth: 1))
                }

                // Handling tips (teal card)
                if !advisory.handlingTips.isEmpty {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        ForEach(advisory.handlingTips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(DS.primary)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(DS.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(DS.Spacing.sm)
                    .background(DS.primary.opacity(0.07))
                    .cornerRadius(DS.Radius.control)
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.control)
                        .stroke(DS.primary.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.surface)
            .cornerRadius(DS.Radius.card)
            .cardShadow()
        }
    }

    // MARK: – Guidance card

    @ViewBuilder
    private var guidanceCard: some View {
        if let text = viewModel.guidance {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack {
                    Label(language.text("Disposal Guidance", "处置指引"),
                          systemImage: "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(DS.primary)
                    Spacer()
                    Button {
                        if speech.isSpeaking { speech.stop() }
                        else { speech.speak(text, language: settingsStore.language) }
                    } label: {
                        Image(systemName: speech.isSpeaking
                              ? "speaker.slash.fill"
                              : "speaker.wave.2.fill")
                            .foregroundColor(speech.isSpeaking ? DS.textSecondary : DS.primary)
                            .font(.subheadline)
                    }
                    .disabled(!settingsStore.voiceEnabled)
                    .opacity(settingsStore.voiceEnabled ? 1 : 0.35)
                }
                Divider()
                Text(text)
                    .font(.body)
                    .foregroundColor(DS.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DS.Spacing.md)
            .background(DS.surface)
            .cornerRadius(DS.Radius.card)
            .cardShadow()
        } else if case .error(let msg) = viewModel.stage {
            Label(msg, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(DS.Spacing.md)
        } else {
            HStack(spacing: DS.Spacing.sm) {
                ProgressView()
                Text(language.text("Awaiting agent response…", "分析中…"))
                    .font(.subheadline)
                    .foregroundColor(DS.textSecondary)
            }
            .padding(DS.Spacing.md)
        }
    }

    // MARK: – Top-3 alternatives

    @ViewBuilder
    private var alternativesSection: some View {
        if let result = viewModel.classificationResult,
           result.allResults.count > 1 {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAlternatives.toggle()
                    }
                } label: {
                    HStack {
                        Text(language.text("Other possibilities", "其他可能"))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(DS.textSecondary)
                        Spacer()
                        Image(systemName: showAlternatives ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(DS.textSecondary)
                    }
                }
                if showAlternatives {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        ForEach(Array(result.allResults.dropFirst().prefix(2).enumerated()),
                                id: \.offset) { _, alt in
                            HStack {
                                Text(alt.displayLabel)
                                    .font(.caption)
                                    .foregroundColor(DS.textPrimary)
                                Spacer()
                                Text("\(Int(alt.confidence * 100))%")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(DS.textSecondary)
                            }
                        }
                    }
                    .padding(.top, DS.Spacing.xs)
                }
            }
            .padding(DS.Spacing.md)
            .background(DS.surface)
            .cornerRadius(DS.Radius.card)
            .cardShadow()
        }
    }

    // MARK: – Sorting demo link

    @ViewBuilder
    private var sortingDemoLink: some View {
        if let cat = resolvedCategory {
            NavigationLink {
                CategoryDemoView(initialCategory: cat)
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundColor(cat.color)
                    Text(language.text("How to sort this →", "查看分类演示 →"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(cat.color)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(DS.border)
                }
                .padding(DS.Spacing.md)
                .background(cat.color.opacity(0.08))
                .cornerRadius(DS.Radius.control)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.control)
                    .stroke(cat.color.opacity(0.25), lineWidth: 1))
            }
        }
    }

    // MARK: – Save button

    private var saveButton: some View {
        Button {
            guard !saved,
                  let result = viewModel.classificationResult,
                  let cat    = resolvedCategory else { return }
            historyStore.add(ScanRecord(
                objectLabel:   result.label,
                objectLabelCN: MappingService.chineseDisplayName(for: result.label),
                category:      cat,
                confidence:    result.confidence,
                co2SavedKg:    ImpactService.co2Saved(for: result.label),
                source:        viewModel.scanSource
            ))
            saved = true
        } label: {
            Label(
                saved
                    ? language.text("Saved ✓", "已保存 ✓")
                    : language.text("Save to History", "保存记录"),
                systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down"
            )
            .font(.headline)
            .foregroundColor(saved ? DS.success : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(saved ? DS.success.opacity(0.15) : DS.primary)
            .cornerRadius(DS.Radius.control)
            .cardShadow()
        }
        .disabled(saved || viewModel.guidance == nil)
        .animation(.easeInOut(duration: 0.2), value: saved)
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResultView(viewModel: ScanViewModel())
                .environmentObject(HistoryStore())
                .environmentObject(SettingsStore())
        }
    }
}
