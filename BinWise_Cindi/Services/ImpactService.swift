import Foundation

/// Provides estimated CO₂ savings (kg) per correctly sorted waste object.
///
/// TODO: Replace placeholder values with peer-reviewed lifecycle-assessment figures,
///       e.g. EPA WARM (Waste Reduction Model) or Chinese GB/T 24040 LCA standard.
///       Cite the source version and retrieval date when updating.
enum ImpactService {

    private static let co2Table: [String: Double] = [
        // Recyclables
        "plastic":        0.08,
        "plastic_bottle": 0.08,
        "metal":          0.09,
        "metal_can":      0.09,
        "glass":          0.03,
        "paper":          0.02,
        "cardboard":      0.03,
        // Kitchen
        "food_waste":     0.05,
        // Hazardous
        "battery":        0.10,
        // Other
        "other_trash":    0.00,
    ]

    /// Returns the estimated kg of CO₂ saved by correctly sorting the given label.
    static func co2Saved(for label: String) -> Double {
        co2Table[label.lowercased()] ?? 0.00
    }
}
