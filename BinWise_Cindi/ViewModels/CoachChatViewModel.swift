import Foundation

/// Drives the Coach chatbot: manages conversation history, delegates to ClaudeService,
/// and persists the last 20 messages to UserDefaults for cross-session continuity.
@MainActor
final class CoachChatViewModel: ObservableObject {

    // MARK: – Published state

    @Published var messages:      [ChatMessage] = []
    @Published var inputText:     String        = ""
    @Published var isLoading:     Bool          = false
    @Published var errorMessage:  String?       = nil

    // MARK: – Dependencies (injected via configure)

    private var historyStore: HistoryStore?
    private var quizStore:    QuizStore?

    private let claude      = ClaudeService()
    private let storageKey  = "coachChatHistory_v1"
    /// Maximum messages kept in memory and persisted (trims oldest first).
    private let maxHistory  = 20

    // MARK: – Injection

    /// Injects stores and loads persisted history. Call from CoachChatView.onAppear.
    func configure(historyStore: HistoryStore, quizStore: QuizStore) {
        guard self.historyStore == nil else { return }   // once per view lifetime
        self.historyStore = historyStore
        self.quizStore    = quizStore
        loadPersistedMessages()
    }

    // MARK: – Public actions

    /// Appends the user message, calls the Coach API, and appends the reply.
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        inputText    = ""
        isLoading    = true
        errorMessage = nil

        do {
            let reply = try await claude.chatWithCoach(
                history: Array(messages.prefix(maxHistory)),
                userMessage: text,
                weakCategories: computeWeakCategories(),
                recentItems: getRecentItems()
            )
            messages.append(ChatMessage(role: .assistant, content: reply))
            persistMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Clears conversation history from memory and UserDefaults.
    func clearChat() {
        messages = []
        persistMessages()
    }

    // MARK: – Private helpers

    /// Returns the top-2 quiz weak spots as readable category names.
    private func computeWeakCategories() -> [String] {
        guard let stats = quizStore?.stats else { return [] }
        return stats.perCategoryMistakes
            .sorted { $0.value > $1.value }
            .prefix(2)
            .compactMap { WasteCategory(rawValue: $0.key)?.englishName }
    }

    /// Returns the last 5 sorted item labels from history.
    private func getRecentItems() -> [String] {
        guard let store = historyStore else { return [] }
        return store.records.prefix(5).map(\.objectLabel)
    }

    /// Encodes the last `maxHistory` messages to UserDefaults.
    private func persistMessages() {
        let recent = Array(messages.suffix(maxHistory))
        if let data = try? JSONEncoder().encode(recent) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Restores messages from UserDefaults on first launch.
    private func loadPersistedMessages() {
        guard let data  = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([ChatMessage].self, from: data)
        else { return }
        messages = saved
    }
}
