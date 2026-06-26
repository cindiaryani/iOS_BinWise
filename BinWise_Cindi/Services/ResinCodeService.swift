import Foundation

/// Parses OCR text to identify plastic resin codes (1–7) and common packaging materials.
/// Used after OCRService produces a list of lines from a packaging label image.
enum ResinCodeService {

    // Ordered from most-specific to least-specific so the first match wins.
    // Each tuple: (NSRegularExpression-compatible pattern, human-readable material name)
    private static let patterns: [(String, String)] = [
        (#"(?i)\bPETE?\b"#,                               "PET (1) plastic"),
        (#"(?i)\bHDPE\b"#,                                "HDPE (2) plastic"),
        (#"(?i)\bPVC\b"#,                                 "PVC (3) plastic"),
        (#"(?i)\bLDPE\b"#,                                "LDPE (4) plastic"),
        (#"(?i)\bPP\b"#,                                  "PP (5) plastic"),
        (#"(?i)\bPS\b"#,                                  "PS (6) plastic"),
        (#"(?i)\bglass\b"#,                               "glass"),
        (#"(?i)\balumini?um\b|\baluminum\b"#,             "aluminium"),
        (#"(?i)\bsteel\b|\btin\b"#,                      "steel/tin"),
        (#"(?i)\bpaper\b|\bcardboard\b|\bcarton\b"#,     "paper/cardboard"),
        (#"(?i)\bplastic\b"#,                             "plastic"),
    ]

    // Mapping from resin digit strings to names (used in the recycling-symbol fallback).
    private static let resinDigitNames: [(String, String)] = [
        ("1", "PET (1) plastic"),  ("2", "HDPE (2) plastic"),
        ("3", "PVC (3) plastic"),  ("4", "LDPE (4) plastic"),
        ("5", "PP (5) plastic"),   ("6", "PS (6) plastic"),
        ("7", "Other (7) plastic"),
    ]

    /// Scans all OCR lines for a resin code or material keyword.
    /// Returns a human-readable material descriptor, or `nil` if nothing is recognised.
    static func parse(_ lines: [String]) -> String? {
        let joined = lines.joined(separator: " ")

        // Primary pass: named keywords and abbreviations
        for (pattern, material) in patterns {
            if joined.range(of: pattern, options: .regularExpression) != nil {
                return material
            }
        }

        // Fallback: bare resin digit near a recycling context hint
        let lower = joined.lowercased()
        let hasRecyclingContext = joined.contains("♻") || lower.contains("recycl") || lower.contains("resin")
        if hasRecyclingContext {
            for (digit, name) in resinDigitNames {
                if joined.range(of: "\\b\(digit)\\b", options: .regularExpression) != nil {
                    return name
                }
            }
        }

        return nil
    }
}
