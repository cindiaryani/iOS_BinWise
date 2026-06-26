import Foundation

/// Central configuration constants and secrets loader.
enum Config {
    /// Base URL for the Claude Messages API.
    static let baseURL = "https://api.anthropic.com"

    /// Claude model used by both agents.
    static let model = "claude-sonnet-4-6"

    /// API key loaded from Secrets.plist (gitignored).
    /// Returns an empty string when the file is absent so the app runs in stub mode.
    static var apiKey: String {
        guard let url  = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url),
              let key  = dict["CLAUDE_API_KEY"] as? String else { return "" }
        return key
    }

    static let interpreterMaxTokens = 256
    static let advisorMaxTokens     = 512
    /// Coach Agent returns 2-3 short bilingual tips — 300 tokens is ample.
    static let coachMaxTokens       = 300
}
