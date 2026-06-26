import Foundation

/// Structured JSON output produced by the Interpreter Agent (Claude call 1).
struct AgentAssessment: Codable {
    /// Item name as interpreted by the agent.
    let item: String
    /// Proposed WasteCategory raw value.
    let category: String
    /// Agent confidence descriptor, e.g. "high", "medium", "low".
    let certainty: String
    /// True when the item's bin depends on a condition (e.g. soiled paper).
    let needsClarification: Bool
    /// Optional clarifying question to surface to the user.
    let clarifyingQuestion: String?

    enum CodingKeys: String, CodingKey {
        case item, category, certainty
        case needsClarification = "needs_clarification"
        case clarifyingQuestion = "clarifying_question"
    }
}
