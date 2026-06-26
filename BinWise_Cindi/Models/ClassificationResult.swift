import Foundation

/// Top-1 classification result from the WasteClassifier model.
struct ClassificationResult {
    let label: String           // raw model label, e.g. "food_waste"
    let confidence: Double      // 0.0 – 1.0
    let allResults: [ClassificationCandidate]  // top-3 for display

    var displayLabel: String {
        label.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var isLowConfidence: Bool { confidence < 0.70 }

    func meetsThreshold(_ threshold: Double = 0.70) -> Bool { confidence >= threshold }
}

struct ClassificationCandidate {
    let label: String
    let confidence: Double
    var displayLabel: String {
        label.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
