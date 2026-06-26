import Foundation

/// Maps Core ML output label strings to WasteCategory bins.
/// Label strings MUST match the training folder names used by WasteClassifier.mlmodel.
enum MappingService {

    private static let table: [String: WasteCategory] = [
        "plastic":     .recyclable,
        "paper":       .recyclable,
        "cardboard":   .recyclable,
        "metal":       .recyclable,
        "glass":       .recyclable,
        "food_waste":  .kitchen,
        "battery":     .hazardous,
        "other_trash": .other,
    ]

    /// Returns the WasteCategory for a Core ML label, defaulting to `.other`.
    static func category(for label: String) -> WasteCategory {
        table[label.lowercased()] ?? .other
    }

    /// Human-readable display name for a model label (e.g. "food_waste" → "Food Waste").
    static func displayName(for label: String) -> String {
        label.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Chinese display name for a Core ML label (e.g. "plastic" → "塑料").
    static func chineseDisplayName(for label: String) -> String {
        let cnTable: [String: String] = [
            "plastic":     "塑料",
            "paper":       "纸张",
            "cardboard":   "纸板",
            "metal":       "金属",
            "glass":       "玻璃",
            "food_waste":  "厨余垃圾",
            "battery":     "电池",
            "other_trash": "其他垃圾",
        ]
        return cnTable[label.lowercased()]
            ?? label.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
