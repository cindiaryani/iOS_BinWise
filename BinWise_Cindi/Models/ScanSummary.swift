import Foundation

/// Lightweight roll-up of a ScanRecord used by charts and aggregate statistics.
/// Avoids passing heavy arrays into every charting component.
struct ScanSummary: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let category: WasteCategory
    let co2SavedKg: Double
}
