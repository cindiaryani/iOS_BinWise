import Foundation

/// A single candidate detection produced by the Vision + Core ML pipeline.
struct WasteObject: Identifiable {
    let id = UUID()
    /// Raw label string from the Core ML model — must match training folder names.
    let label: String
    /// Core ML classification confidence in the range 0.0–1.0.
    let confidence: Float
}
