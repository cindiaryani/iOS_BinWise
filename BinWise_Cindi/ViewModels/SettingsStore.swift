import SwiftUI

// MARK: – Language

/// User's preferred display and speech language.
enum AppLanguage: String, CaseIterable, Codable {
    case chinese = "中文"
    case english = "English"
    case both    = "Both / 双语"

    /// Returns the appropriate string for this language setting.
    /// Use throughout the app instead of hardcoded bilingual strings.
    func text(_ en: String, _ zh: String) -> String {
        switch self {
        case .english: return en
        case .chinese: return zh
        case .both:    return "\(en)  \(zh)"
        }
    }
}

// MARK: – Environment key (allows any view to read the language without settingsStore)

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .both
}

extension EnvironmentValues {
    /// Current app language — set at root from SettingsStore and propagated to all views.
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}

// MARK: – Store

/// UserDefaults-backed settings store, observable by all views via environment.
final class SettingsStore: ObservableObject {

    // MARK: – Settings

    /// Whether voice read-aloud is enabled on ResultView.
    @Published var voiceEnabled: Bool = true {
        didSet { UserDefaults.standard.set(voiceEnabled, forKey: Keys.voiceEnabled) }
    }

    /// Display and TTS language preference.
    @Published var language: AppLanguage = .both {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    /// Minimum Vision confidence to treat a classification as stable (live camera).
    @Published var confidenceThreshold: Double = 0.70 {
        didSet { UserDefaults.standard.set(confidenceThreshold, forKey: Keys.threshold) }
    }

    /// Set to true after the user completes the onboarding flow.
    @Published var hasSeenOnboarding: Bool = false {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.onboarding) }
    }

    // MARK: – Init

    init() {
        let ud = UserDefaults.standard
        voiceEnabled        = ud.object(forKey: Keys.voiceEnabled) as? Bool ?? true
        confidenceThreshold = ud.object(forKey: Keys.threshold) as? Double ?? 0.70
        hasSeenOnboarding   = ud.bool(forKey: Keys.onboarding)
        if let raw  = ud.string(forKey: Keys.language),
           let lang = AppLanguage(rawValue: raw) {
            language = lang
        }
    }

    // MARK: – Private

    private enum Keys {
        static let voiceEnabled = "voiceEnabled"
        static let language     = "appLanguage"
        static let threshold    = "confidenceThreshold"
        static let onboarding   = "hasSeenOnboarding"
    }
}
