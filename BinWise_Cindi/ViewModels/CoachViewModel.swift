import Foundation

/// Calls the Coach Agent and publishes its personalised tips.
/// Call `load(historyStore:quizStore:)` from CoachView.onAppear.
@MainActor
final class CoachViewModel: ObservableObject {

    @Published private(set) var tips: String        = ""
    @Published private(set) var isLoading: Bool     = false
    @Published private(set) var errorMessage: String? = nil

    private let claude = ClaudeService()

    // MARK: – Public

    /// Fetches personalised Coach-Agent tips based on the user's history and quiz mistakes.
    func load(historyStore: HistoryStore, quizStore: QuizStore) {
        guard !isLoading else { return }
        isLoading     = true
        errorMessage  = nil
        Task {
            do {
                tips = try await claude.coach(records: historyStore.records,
                                               quizStats: quizStore.stats)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// Clears the current tips and reloads.
    func refresh(historyStore: HistoryStore, quizStore: QuizStore) {
        tips = ""
        load(historyStore: historyStore, quizStore: quizStore)
    }
}
