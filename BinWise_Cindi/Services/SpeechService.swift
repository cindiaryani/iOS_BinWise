import AVFoundation

/// Wraps AVSpeechSynthesizer to read disposal guidance aloud.
/// Create as @StateObject in ResultView so the synthesizer is released when the view leaves.
final class SpeechService: NSObject, ObservableObject {

    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: – Public interface

    /// Speaks `text` using a voice appropriate for `language`.
    /// Activates the shared AVAudioSession for playback then stops any in-progress speech.
    func speak(_ text: String, language: AppLanguage) {
        // Activate audio session — required for AVSpeechSynthesizer to produce output.
        // Uses .duckOthers so background music lowers rather than cutting out entirely.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try session.setActive(true)
        } catch {
            // Failure is non-fatal; the synthesizer will try to speak on whatever route exists.
        }

        stop()

        // Strip leading emoji characters that TTS engines read as their accessibility labels
        // (e.g. "white heavy check mark", "clipboard"). Keep the words only.
        let cleaned = text.components(separatedBy: "\n")
            .map { line -> String in
                // Drop leading non-letter/non-digit prefix so "✅ Category: ..." → "Category: ..."
                if let idx = line.unicodeScalars.firstIndex(where: {
                    CharacterSet.letters.union(.decimalDigits).contains($0)
                }) {
                    return String(line[idx...])
                }
                return line
            }
            .joined(separator: ". ")

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
        switch language {
        case .chinese:
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        case .english, .both:
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Stops speech immediately and deactivates the audio session.
    func stop() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: – Delegate

extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
