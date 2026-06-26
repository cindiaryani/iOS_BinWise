import SwiftUI

/// Waste-sorting quiz: 4-button multiple choice with immediate feedback and explanations.
struct QuizView: View {
    @EnvironmentObject var quizStore: QuizStore
    @StateObject private var vm = QuizViewModel()
    @Environment(\.appLanguage) var language

    var body: some View {
        ZStack {
            DS.background.ignoresSafeArea()
            VStack(spacing: 0) {
                scoreBar
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.top, DS.Spacing.md)

                modeAndWeakSpotRow
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.top, DS.Spacing.sm)

                if let item = vm.currentItem {
                    ScrollView {
                        VStack(spacing: DS.Spacing.lg) {
                            questionCard(item: item)
                            answerButtons(item: item)
                            if case .feedback(let correct) = vm.phase {
                                feedbackExplanationCard(item: item, correct: correct)
                            }
                        }
                        .padding(DS.Spacing.md)
                        .padding(.bottom, 90)
                        .animation(.spring(response: 0.35), value: vm.phase)
                    }
                } else {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .navigationTitle(language.text("Quiz", "垃圾分类测验"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.configure(with: quizStore) }
        .safeAreaInset(edge: .bottom) {
            if case .feedback = vm.phase {
                nextQuestionBar
            } else {
                Color.clear.frame(height: 90)
            }
        }
    }

    // MARK: – Pinned "Next Question" bar (Section C: pinned via safeAreaInset, not in ScrollView)

    private var nextQuestionBar: some View {
        Button {
            withAnimation { vm.nextQuestion() }
        } label: {
            Text(language.text("Next Question", "下一题"))
                .primaryButtonStyle()
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, 90)
        .background(DS.background.opacity(0.95))
    }

    // MARK: – Score bar

    private var scoreBar: some View {
        HStack {
            scoreChip(icon: "checkmark.circle.fill",
                      color: DS.success,
                      label: "\(vm.sessionScore) \(language.text("correct", "正确"))")
            Spacer()
            scoreChip(icon: "flame.fill",
                      color: .orange,
                      label: "\(language.text("Streak", "连续")) \(vm.streak)")
            Spacer()
            scoreChip(icon: "trophy.fill",
                      color: DS.primary,
                      label: "\(language.text("Best", "最佳")) \(vm.bestStreak)")
        }
        .padding(DS.Spacing.md)
        .cardStyle()
    }

    private func scoreChip(icon: String, color: Color, label: String) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon).foregroundColor(color)
            Text(label).font(.caption.weight(.semibold)).foregroundColor(DS.textPrimary)
        }
    }

    // MARK: – Practice mode toggle + weak-spot hint

    private var weakestCategory: WasteCategory? {
        quizStore.stats.perCategoryMistakes
            .max(by: { $0.value < $1.value })
            .flatMap { WasteCategory(rawValue: $0.key) }
    }

    private var modeAndWeakSpotRow: some View {
        HStack(spacing: DS.Spacing.sm) {
            Button {
                vm.trickyOnlyMode.toggle()
            } label: {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: vm.trickyOnlyMode ? "brain.head.profile" : "shuffle")
                        .font(.caption)
                    Text(vm.trickyOnlyMode
                         ? language.text("Tricky Only", "仅易错题")
                         : language.text("All Items", "全部题目"))
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(vm.trickyOnlyMode ? .white : DS.textPrimary)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, 6)
                .background(vm.trickyOnlyMode ? DS.brandAmberDeep : DS.brandAmberTint)
                .cornerRadius(DS.Radius.badge)
            }

            if let weak = weakestCategory {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text(language.text("Weak spot: \(weak.englishName)", "弱项：\(weak.chineseName)"))
                        .font(.caption2.weight(.medium))
                        .foregroundColor(DS.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
    }

    // MARK: – Question card

    private func questionCard(item: QuizItem) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            Text(language.text("Which bin?", "放哪里？"))
                .font(.caption.weight(.medium))
                .foregroundColor(DS.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(language.text(item.name, item.chineseName))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if language == .both {
                Text(item.chineseName)
                    .font(.title3.weight(.medium))
                    .foregroundColor(DS.textSecondary)
            }

            Image(systemName: "questionmark.square.dashed")
                .font(.system(size: 64))
                .foregroundColor(DS.border)
                .padding(.vertical, DS.Spacing.sm)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: – Answer buttons

    private var inFeedbackPhase: Bool {
        if case .feedback = vm.phase { return true }
        return false
    }

    private func answerButtons(item: QuizItem) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            ForEach(WasteCategory.allCases, id: \.self) { cat in
                answerButton(cat: cat, item: item)
            }
        }
    }

    @ViewBuilder
    private func answerButton(cat: WasteCategory, item: QuizItem) -> some View {
        let isSelected = vm.selectedCategory == cat
        let isCorrect  = cat == item.correctCategory
        let inFeedback = inFeedbackPhase

        let bg: Color = {
            guard inFeedback else { return DS.surface }
            if isCorrect  { return DS.success.opacity(0.15) }
            if isSelected { return Color.red.opacity(0.12) }
            return DS.surface
        }()
        let border: Color = {
            guard inFeedback else { return DS.border }
            if isCorrect  { return DS.success }
            if isSelected { return Color.red }
            return DS.border
        }()
        let textColor: Color = {
            guard inFeedback else { return DS.textPrimary }
            if isCorrect  { return DS.success }
            if isSelected { return Color.red }
            return DS.textSecondary
        }()

        Button {
            guard vm.phase == .question else { return }
            withAnimation { vm.answer(cat) }
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: cat.iconName)
                    .foregroundColor(inFeedback && (isCorrect || isSelected) ? textColor : cat.color)
                    .font(.title3)
                    .frame(width: 28)
                Text(language.text(cat.englishName, cat.chineseName))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(textColor)
                Spacer()
                if inFeedback {
                    if isCorrect  { Image(systemName: "checkmark.circle.fill").foregroundColor(DS.success) }
                    else if isSelected { Image(systemName: "xmark.circle.fill").foregroundColor(.red) }
                }
            }
            .padding(DS.Spacing.md)
            .background(bg)
            .cornerRadius(DS.Radius.control)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.control).stroke(border, lineWidth: 1.5))
        }
        .disabled(inFeedback)
        .animation(.easeInOut(duration: 0.2), value: vm.phase)
    }

    // MARK: – Feedback explanation card (button lives in the pinned safeAreaInset bar)

    private func feedbackExplanationCard(item: QuizItem, correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(correct ? DS.success : .red)
                    .font(.title2)
                Text(correct
                     ? language.text("Correct!", "答对了！")
                     : language.text("Not quite.", "再想想～"))
                    .font(.headline)
                    .foregroundColor(correct ? DS.success : .red)
            }

            Text(item.explanation)
                .font(.body)
                .foregroundColor(DS.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .cardStyle()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuizView()
                .environmentObject(QuizStore())
        }
    }
}
