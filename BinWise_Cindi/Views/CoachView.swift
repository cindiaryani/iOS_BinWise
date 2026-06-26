import SwiftUI

/// Displays personalised bilingual tips from the Coach Agent, driven by sorting history
/// and quiz-mistake data. Refreshes on demand.
struct CoachView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @EnvironmentObject var quizStore: QuizStore
    @StateObject private var vm = CoachViewModel()
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    headerCard
                    tipsSection
                }
                .padding(DS.Spacing.md)
                .padding(.bottom, 90)
            }
        }
        .navigationTitle(language.text("My Coach", "我的教练"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.refresh(historyStore: historyStore, quizStore: quizStore)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(vm.isLoading)
            }
        }
        .onAppear {
            guard vm.tips.isEmpty, !vm.isLoading else { return }
            vm.load(historyStore: historyStore, quizStore: quizStore)
        }
    }

    // MARK: – Header

    private var headerCard: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 44))
                .foregroundColor(DS.primary)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(language.text("AI Coach", "AI 教练"))
                    .font(.title3.weight(.bold))
                    .foregroundColor(DS.textPrimary)
                Text(language.text(
                    "Personalised tips based on your history and quiz results.",
                    "基于你的历史和测验结果的个性化建议。"
                ))
                .font(.caption)
                .foregroundColor(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    // MARK: – Tips section

    @ViewBuilder
    private var tipsSection: some View {
        if vm.isLoading {
            loadingCard
        } else if let err = vm.errorMessage {
            errorCard(err)
        } else if vm.tips.isEmpty {
            emptyState
        } else {
            tipsCard
        }
    }

    private var loadingCard: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .scaleEffect(1.4)
            Text(language.text("Generating your tips…", "正在生成建议…"))
                .font(.subheadline)
                .foregroundColor(DS.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.xxl)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: DS.Spacing.md) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button(language.text("Try Again", "重试")) {
                vm.refresh(historyStore: historyStore, quizStore: quizStore)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(DS.primary)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label(language.text("Your Tips Today", "今日建议"), systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DS.primary)
            Divider()
            Text(vm.tips)
                .font(.body)
                .foregroundColor(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
        }
        .padding(DS.Spacing.md)
        .background(DS.surface)
        .cornerRadius(DS.Radius.card)
        .cardShadow()
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundColor(DS.border)
            Text(language.text("No tips yet", "暂无建议"))
                .font(.title3.weight(.semibold))
                .foregroundColor(DS.textPrimary)
            Text(language.text(
                "Sort a few items and take a quiz to get personalised advice.",
                "先分类几件物品并完成测验，即可获得专属建议。"
            ))
            .multilineTextAlignment(.center)
            .font(.subheadline)
            .foregroundColor(DS.textSecondary)
        }
        .padding(DS.Spacing.xxl)
    }
}

struct CoachView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CoachView()
                .environmentObject(HistoryStore())
                .environmentObject(QuizStore())
        }
    }
}
