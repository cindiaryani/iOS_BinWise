import Foundation

/// A persisted entry in the user's sorting history.
/// Codable-to-file now; structured to migrate to Core Data later.
struct SortRecord: Identifiable, Codable {
    let id: UUID
    /// Human-readable label of the detected item.
    let itemLabel: String
    /// Final assigned disposal category.
    let category: WasteCategory
    /// Bilingual guidance text from the Advisor Agent.
    let guidance: String
    /// Core ML detection confidence (0.0–1.0).
    let confidence: Float
    /// Estimated kg of CO₂ saved by correctly sorting this item (from ImpactService).
    let co2Saved: Double
    /// Timestamp of the sorting event.
    let date: Date

    init(
        id: UUID = UUID(),
        itemLabel: String,
        category: WasteCategory,
        guidance: String,
        confidence: Float,
        co2Saved: Double = 0,
        date: Date = Date()
    ) {
        self.id         = id
        self.itemLabel  = itemLabel
        self.category   = category
        self.guidance   = guidance
        self.confidence = confidence
        self.co2Saved   = co2Saved
        self.date       = date
    }

    /// Custom decode with co2Saved defaulting to 0 for records saved before Build 2.
    init(from decoder: Decoder) throws {
        let c     = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,          forKey: .id)
        itemLabel = try c.decode(String.self,        forKey: .itemLabel)
        category  = try c.decode(WasteCategory.self, forKey: .category)
        guidance  = try c.decode(String.self,        forKey: .guidance)
        confidence = try c.decode(Float.self,        forKey: .confidence)
        co2Saved  = try c.decodeIfPresent(Double.self, forKey: .co2Saved) ?? 0
        date      = try c.decode(Date.self,          forKey: .date)
    }
}
