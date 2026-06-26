import Foundation

// MARK: – Errors

/// Typed errors from the Claude API layer.
enum ClaudeError: Error, LocalizedError {
    case missingAPIKey
    case networkError(Error)
    case httpError(Int)
    case emptyResponse
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:        return "API key not configured. Add it to Secrets.plist."
        case .networkError(let e):  return "Network error: \(e.localizedDescription)"
        case .httpError(let code):  return "API returned HTTP \(code)."
        case .emptyResponse:        return "The API returned an empty response."
        case .decodingError(let m): return "Response parsing failed: \(m)"
        }
    }
}

// MARK: – Codable wire types

private struct ClaudeRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ClaudeMessage]
}

private struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

private struct ClaudeResponse: Decodable {
    struct Content: Decodable {
        let type: String
        let text: String?
    }
    let content: [Content]
}

// MARK: – Service

/// Three-agent pipeline:
///   1. `interpret` — Interpreter Agent classifies the detected object (per-scan).
///   2. `advise`    — Advisor Agent produces bilingual disposal guidance (per-scan).
///   3. `coach`     — Coach Agent gives longitudinal, history-aware personalised tips.
final class ClaudeService {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: – Interpreter Agent

    /// Sends the Vision result to the Interpreter Agent and returns a structured assessment.
    /// Returns a synthesised stub assessment when no API key is configured.
    func interpret(result: ClassificationResult) async throws -> AgentAssessment {
        let apiKey = Config.apiKey
        guard !apiKey.isEmpty else {
            // Simulate Interpreter Agent latency so the stage spinner is visible
            try await Task.sleep(nanoseconds: 1_500_000_000)
            let cat = MappingService.category(for: result.label)
            return AgentAssessment(
                item: result.displayLabel,
                category: cat.rawValue,
                certainty: "high",
                needsClarification: false,
                clarifyingQuestion: nil
            )
        }

        let mapped = MappingService.category(for: result.label)
        let userMessage = """
        Item detected by computer vision: "\(result.displayLabel)" \
        (confidence: \(Int(result.confidence * 100))%).
        Proposed category: \(mapped.englishName).
        Classify this item for China's 4-bin waste system and respond ONLY with JSON.
        """
        let system = """
        You are a waste-item interpreter for China's mandatory 垃圾分类 system.
        Respond ONLY with compact JSON — no code fences, no extra keys — matching this schema:
        {"item":"<string>","category":"<recyclable|hazardous|kitchen|other>",\
        "certainty":"<high|medium|low>","needs_clarification":<bool>,"clarifying_question":<string|null>}
        Set needs_clarification to true when disposal depends on condition (e.g. greasy paper).
        """
        let text = try await callAPI(system: system,
                                     userMessage: userMessage,
                                     maxTokens: Config.interpreterMaxTokens,
                                     apiKey: apiKey)
        return parseAssessment(from: text, fallbackCategory: mapped)
    }

    // MARK: – Advisor Agent

    /// Sends the Interpreter's assessment to the Advisor Agent and returns bilingual guidance.
    /// Returns a polished stub string when no API key is configured.
    func advise(assessment: AgentAssessment,
               userClarification: String?,
               safetyAdvisory: WasteSafetyPolicy.SafetyAdvisory? = nil) async throws -> String {
        let apiKey = Config.apiKey
        guard !apiKey.isEmpty else {
            // Simulate Advisor Agent latency so the stage spinner is visible
            try await Task.sleep(nanoseconds: 1_800_000_000)
            let cat = WasteCategory(rawValue: assessment.category) ?? .other
            return """
            ✅ 分类确认 / Category: \(cat.chineseName) (\(cat.englishName))
            📋 原因 / Reason: Please dispose of this item in the \(cat.englishName) bin.
            ♻️ 提示 / Tip: Rinse containers before sorting to avoid contamination.
            """
        }

        var userMessage = "Item: \"\(assessment.item)\". Proposed category: \(assessment.category). Certainty: \(assessment.certainty)."
        if let c = userClarification, !c.isEmpty {
            userMessage += " User clarification: \(c)."
        }
        if let advisory = safetyAdvisory, !advisory.warnings.isEmpty {
            userMessage += " Safety warnings: \(advisory.warnings.joined(separator: "; "))."
        }
        let system = """
        You are an expert on China's 垃圾分类 4-category mandatory waste-sorting system.
        Given an item and its proposed category, provide SHORT bilingual guidance (中文 + English).
        Use this structure:
        ✅ 分类确认 / Category: [Chinese name (English name)]
        📋 原因 / Reason: [one concise sentence]
        ♻️ 提示 / Tip: [contamination or preparation tip if relevant, consistent with any safety warnings provided]
        Keep the entire response under 80 words.
        """
        return try await callAPI(system: system,
                                 userMessage: userMessage,
                                 maxTokens: Config.advisorMaxTokens,
                                 apiKey: apiKey)
    }

    // MARK: – Coach Agent

    /// Sends the user's sort history and quiz-mistake data to the Coach Agent and returns
    /// 2-3 short bilingual tips focused on their weakest sorting categories.
    /// Returns a polished stub when no API key is configured.
    func coach(records: [ScanRecord], quizStats: QuizStats) async throws -> String {
        let apiKey = Config.apiKey
        guard !apiKey.isEmpty else {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return """
            💡 If paper feels greasy, it goes in Other Trash (其他垃圾) — grease blocks recycling.
               如果纸张油腻，放入其他垃圾——油脂会影响回收。

            🌟 Always rinse bottles and cans before dropping them in the Recyclable bin.
               瓶罐放入可回收物前请先清洗，避免污染。

            🔋 Batteries are Hazardous (有害垃圾) — never put them in regular bins.
               废电池属有害垃圾，请投入专用回收箱。
            """
        }

        let recentLabels = records.prefix(10).map(\.objectLabel).joined(separator: ", ")
        let weakSpots = quizStats.perCategoryMistakes
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { "\($0.key): \($0.value) mistake(s)" }
            .joined(separator: "; ")

        let userMessage = """
        Recent items sorted: \(recentLabels.isEmpty ? "none yet" : recentLabels).
        Quiz weak spots: \(weakSpots.isEmpty ? "none yet" : weakSpots).
        """
        let system = """
        You are a friendly waste-sorting coach (垃圾分类教练) for a user in China practicing \
        the mandatory 垃圾分类 system.
        Given the user's recent sort history and quiz-mistake data, write exactly 2-3 SHORT, \
        encouraging, personalised tips that target their weak spots.
        Format: start each tip with one emoji, then an English sentence, then a blank line, \
        then the Chinese translation of that sentence, then a blank line before the next tip.
        Keep the entire response under 130 words. Do not add a title or header.
        """
        return try await callAPI(system: system,
                                 userMessage: userMessage,
                                 maxTokens: Config.coachMaxTokens,
                                 apiKey: apiKey)
    }

    // MARK: – Coach Chatbot Agent

    /// Multi-turn conversational coach for China's waste-sorting system.
    /// Sends the full conversation history to Claude and returns the assistant's reply.
    /// Returns a keyword-matched stub reply when no API key is configured.
    func chatWithCoach(
        history: [ChatMessage],
        userMessage: String,
        weakCategories: [String],
        recentItems: [String]
    ) async throws -> String {
        let apiKey = Config.apiKey
        guard !apiKey.isEmpty else {
            try await Task.sleep(nanoseconds: 800_000_000)
            return stub(for: userMessage)
        }

        let weakStr   = weakCategories.isEmpty ? "none identified yet" : weakCategories.joined(separator: ", ")
        let recentStr = recentItems.isEmpty    ? "none yet"            : recentItems.joined(separator: ", ")

        let system = """
        You are BinWise Coach (垃圾分类小助手), a friendly bilingual expert on China's 4-category \
        waste sorting system (可回收物/有害垃圾/厨余垃圾/其他垃圾). You help users in China correctly \
        sort their waste. The user's weak categories are: \(weakStr). \
        Their recent sorted items include: \(recentStr).
        Rules: (1) Always answer in BOTH Chinese and English. (2) Be friendly, encouraging, concise. \
        (3) For any item asked about, give the correct China category + a one-line reason. \
        (4) If asked about tricky cases (tissues, pizza boxes, phone batteries, etc.) explain the \
        common mistake and the correct answer. (5) Max 3 sentences per reply. \
        (6) Never make up rules — only use China's official 4-category system.
        """

        // Build messages array from history + new message.
        // Trim to last 20 messages to keep token count bounded.
        let historyCapped = Array(history.suffix(20))
        var messages: [ClaudeMessage] = historyCapped.map {
            ClaudeMessage(role: $0.role.rawValue, content: $0.content)
        }
        // Append current user message if it's not already the last element.
        if messages.last?.content != userMessage || messages.last?.role != "user" {
            messages.append(ClaudeMessage(role: "user", content: userMessage))
        }

        return try await callChatAPI(system: system,
                                     messages: messages,
                                     maxTokens: Config.coachMaxTokens,
                                     apiKey: apiKey)
    }

    /// Keyword-matched stub replies for the Coach chatbot (no API key).
    private func stub(for message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("tissue") || lower.contains("纸巾") {
            return "Used tissues go to 其他垃圾 (Other)! 🗑\n用过的纸巾属于其他垃圾！纸巾含水分和污染物，无法回收。"
        }
        if lower.contains("battery") || lower.contains("电池") {
            return "Batteries are 有害垃圾 (Hazardous)! ⚠️\n电池属于有害垃圾！含有重金属，请投入专用有害垃圾回收箱。"
        }
        if lower.contains("phone") || lower.contains("手机") || lower.contains("smartphone") {
            return "Smartphones go to 有害垃圾 (Hazardous) due to the lithium battery! 📱\n手机属于有害垃圾（因为含锂电池）！请厂商以旧换新或送至专用电子废弃物回收点。"
        }
        if lower.contains("pizza") || lower.contains("比萨") || lower.contains("greasy") || lower.contains("油腻") {
            return "Greasy pizza boxes go to 其他垃圾 (Other). The clean lid can be torn off and recycled! 📦\n油腻的比萨盒属于其他垃圾。但干净的盒盖可以撕下来放入可回收物！"
        }
        if lower.contains("bone") || lower.contains("骨头") {
            return "Small soft bones (chicken) → 厨余垃圾. Large hard bones (pork/beef) → 其他垃圾. 🦴\n小骨头（鸡骨）→厨余垃圾；大骨头（猪骨/牛骨）→其他垃圾。大小决定分类！"
        }
        return "Great question! Connect an API key in Secrets.plist to get personalised answers. 🤖\n好问题！在Secrets.plist中配置API密钥后，我可以给你更详细的个性化解答。"
    }

    // MARK: – Private helpers

    /// Sends a multi-message conversation to the Claude API.
    private func callChatAPI(system: String,
                             messages: [ClaudeMessage],
                             maxTokens: Int,
                             apiKey: String) async throws -> String {
        guard let url = URL(string: "\(Config.baseURL)/v1/messages") else {
            throw ClaudeError.decodingError("Invalid base URL")
        }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(
            ClaudeRequest(model: Config.model,
                          max_tokens: maxTokens,
                          system: system,
                          messages: messages)
        )
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClaudeError.networkError(error)
        }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ClaudeError.httpError(http.statusCode)
        }
        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text,
              !text.isEmpty else {
            throw ClaudeError.emptyResponse
        }
        return text
    }

    private func callAPI(system: String,
                         userMessage: String,
                         maxTokens: Int,
                         apiKey: String) async throws -> String {
        guard let url = URL(string: "\(Config.baseURL)/v1/messages") else {
            throw ClaudeError.decodingError("Invalid base URL in Config.baseURL")
        }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey,             forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(
            ClaudeRequest(model: Config.model,
                          max_tokens: maxTokens,
                          system: system,
                          messages: [ClaudeMessage(role: "user", content: userMessage)])
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClaudeError.networkError(error)
        }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ClaudeError.httpError(http.statusCode)
        }
        let decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = decoded.content.first(where: { $0.type == "text" })?.text,
              !text.isEmpty else {
            throw ClaudeError.emptyResponse
        }
        return text
    }

    /// Parses a JSON string into an AgentAssessment, stripping markdown code fences if present.
    /// Falls back to a synthetic assessment on parse failure — never throws.
    private func parseAssessment(from text: String,
                                 fallbackCategory: WasteCategory) -> AgentAssessment {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            let lines = cleaned.components(separatedBy: "\n")
            cleaned = lines.dropFirst().dropLast().joined(separator: "\n")
        }
        if let data = cleaned.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(AgentAssessment.self, from: data) {
            return parsed
        }
        return AgentAssessment(
            item: "detected item",
            category: fallbackCategory.rawValue,
            certainty: "medium",
            needsClarification: false,
            clarifyingQuestion: nil
        )
    }
}
