import Foundation

/// Persists QuizStats as JSON in the app's Documents directory,
/// parallel to sort_history.json. Structured for a straightforward Core Data swap later.
final class QuizStore: ObservableObject {

    @Published private(set) var stats = QuizStats()

    private let fileURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("quiz_stats.json")
    }()

    init() { load() }

    /// Replaces the persisted stats and notifies subscribers.
    func save(_ updated: QuizStats) {
        stats = updated
        persist()
    }

    /// Wipes all quiz progress and persists the reset state.
    func reset() {
        stats = QuizStats()
        persist()
    }

    // MARK: – Private

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else { return }
        stats = (try? JSONDecoder().decode(QuizStats.self, from: data)) ?? QuizStats()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        try? data.write(to: fileURL, options: .atomicWrite)
    }
}
