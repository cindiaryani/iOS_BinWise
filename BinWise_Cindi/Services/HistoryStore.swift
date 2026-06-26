import Foundation

/// Persists and queries the user's scan history as a typed [ScanRecord] array.
/// Backed by UserDefaults (key: "scanRecords"), capped at 500 entries.
/// Performs a one-time best-effort migration of the legacy SortRecord file on first launch.
@MainActor
final class HistoryStore: ObservableObject {

    @Published private(set) var records: [ScanRecord] = []

    private let defaults  = UserDefaults.standard
    private let storeKey  = "scanRecords"
    private let maxCap    = 500

    init() {
        load()
        migrateFromLegacyFileIfNeeded()
    }

    // MARK: – Write

    /// Inserts a record at the front, trims to cap, and persists.
    func add(_ record: ScanRecord) {
        records.insert(record, at: 0)
        if records.count > maxCap { records = Array(records.prefix(maxCap)) }
        persist()
    }

    /// Alias kept for callsites that used the old `save` name.
    func save(_ record: ScanRecord) { add(record) }

    /// Removes records at the given IndexSet (for swipe-to-delete in List).
    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        persist()
    }

    /// Removes a specific record by identity.
    func delete(_ record: ScanRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    /// Clears all records.
    func clear() {
        records = []
        persist()
    }

    /// Legacy alias.
    func resetAll() { clear() }

    // MARK: – Read

    /// Returns all records (newest first).
    func all() -> [ScanRecord] { records }

    /// Returns at most the n most-recent records.
    func recent(_ n: Int) -> [ScanRecord] { Array(records.prefix(n)) }

    /// Returns lightweight ScanSummary roll-ups for use in chart components.
    func summaries() -> [ScanSummary] {
        records.map {
            ScanSummary(id: $0.id, date: $0.date, category: $0.category, co2SavedKg: $0.co2SavedKg)
        }
    }

    /// Returns the count of records per WasteCategory.
    func countByCategory() -> [WasteCategory: Int] {
        Dictionary(grouping: records, by: \.category).mapValues(\.count)
    }

    /// Returns the cumulative CO₂ saved across all records.
    func totalCO2() -> Double {
        records.reduce(0) { $0 + $1.co2SavedKg }
    }

    // MARK: – Private persistence

    private func load() {
        guard let data = defaults.data(forKey: storeKey) else { return }
        records = (try? JSONDecoder().decode([ScanRecord].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storeKey)
    }

    /// One-time migration: converts the legacy SortRecord JSON file → ScanRecord UserDefaults.
    /// Runs only when the new store is empty, so it never overwrites real data.
    private func migrateFromLegacyFileIfNeeded() {
        guard records.isEmpty else { return }
        let legacyURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sort_history.json")
        guard FileManager.default.fileExists(atPath: legacyURL.path),
              let data = try? Data(contentsOf: legacyURL),
              let old  = try? JSONDecoder().decode([SortRecord].self, from: data),
              !old.isEmpty else { return }
        records = old.map {
            ScanRecord(
                id:            $0.id,
                date:          $0.date,
                objectLabel:   $0.itemLabel,
                objectLabelCN: MappingService.chineseDisplayName(for: $0.itemLabel),
                category:      $0.category,
                confidence:    Double($0.confidence),
                co2SavedKg:    $0.co2Saved,
                source:        .photo
            )
        }
        persist()
    }
}
