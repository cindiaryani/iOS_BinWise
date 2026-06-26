import Foundation

/// A structured, persisted record of one completed scan event.
struct ScanRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    /// Core ML output label (e.g. "plastic", "food_waste").
    let objectLabel: String
    /// Chinese display name (e.g. "塑料").
    let objectLabelCN: String
    let category: WasteCategory
    /// Core ML confidence score (0.0–1.0).
    let confidence: Double
    /// Estimated kg CO₂ saved by correctly sorting this item.
    let co2SavedKg: Double
    let source: ScanSource

    /// Identifies how the scan was initiated.
    enum ScanSource: String, Codable {
        case liveCamera, photo, barcode, quiz
    }

    /// Human-readable display label with underscores replaced by spaces.
    var displayLabel: String {
        objectLabel.replacingOccurrences(of: "_", with: " ").capitalized
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        objectLabel: String,
        objectLabelCN: String,
        category: WasteCategory,
        confidence: Double,
        co2SavedKg: Double,
        source: ScanSource
    ) {
        self.id            = id
        self.date          = date
        self.objectLabel   = objectLabel
        self.objectLabelCN = objectLabelCN
        self.category      = category
        self.confidence    = confidence
        self.co2SavedKg    = co2SavedKg
        self.source        = source
    }
}
