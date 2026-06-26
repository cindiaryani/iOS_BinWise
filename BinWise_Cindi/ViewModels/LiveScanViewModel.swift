import SwiftUI
import AVFoundation

// MARK: – Scan state

/// Live camera pipeline state.
enum LiveScanState: Equatable {
    /// No stable prediction yet.
    case searching
    /// A candidate is stabilising — progress is 0.0 → 1.0.
    case locking(Double)
    /// Prediction locked; pipeline is about to fire.
    case locked
    /// Agent pipeline is running.
    case processing

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.searching, .searching), (.locked, .locked), (.processing, .processing): return true
        case (.locking(let a), .locking(let b)): return abs(a - b) < 0.01
        default: return false
        }
    }
}

// MARK: – ViewModel

/// State machine for the live real-time classification flow.
///
/// Receives per-frame predictions from `LiveCameraPreviewView`, tracks stability,
/// and auto-triggers the existing ScanViewModel agent pipeline once a prediction locks.
@MainActor
final class LiveScanViewModel: ObservableObject {

    // MARK: – Published state

    @Published var scanState: LiveScanState = .searching
    @Published var currentLabel: String     = ""
    @Published var currentConfidence: Float = 0
    @Published var currentCategory: WasteCategory = .other
    /// Becomes true when auto-lock fails within `fallbackDelay` seconds.
    @Published var showFallbackButton: Bool = false
    /// Permission denied — shown instead of camera content.
    @Published var permissionDenied: Bool   = false

    // MARK: – Closure fired when auto-lock or manual tap triggers the agent pipeline

    /// Set by the container view. Receives the locked ClassificationResult and a still frame.
    var onAutoTrigger: ((ClassificationResult, UIImage?) -> Void)?

    // MARK: – Stability tracking

    private var stabilityLabel      = ""
    private var stabilityCount      = 0
    private let stabilityThreshold  = 8   // ~1.6 s at 5 fps
    /// Prevents re-firing for the same item after a cooldown.
    private var cooldownLabel: String? = nil
    /// Still frame captured at lock time, passed to ResultView.
    private(set) var lockedImage: UIImage?

    // MARK: – Fallback timer

    private var fallbackTask: Task<Void, Never>?
    private let fallbackDelay: TimeInterval = 3.5

    // MARK: – Frame updates (nonisolated — called from background capture queue)

    /// Called by the camera coordinator on each classified frame.
    nonisolated func processFrame(label: String, confidence: Float, capturedImage: UIImage?) {
        Task { @MainActor [weak self] in
            self?.update(label: label, confidence: confidence, capturedImage: capturedImage)
        }
    }

    // MARK: – State machine (main actor)

    private func update(label: String, confidence: Float, capturedImage: UIImage?) {
        // Ignore frames while locked or processing
        guard scanState != .processing, scanState != .locked else { return }

        currentLabel      = label
        currentConfidence = confidence
        currentCategory   = MappingService.category(for: label)

        // Cooldown: same label already processed → skip until it changes
        if let cooldown = cooldownLabel {
            if label != cooldown {
                cooldownLabel = nil   // new object — reset cooldown
            } else {
                return
            }
        }

        let isStable = confidence >= 0.70

        if label == stabilityLabel, isStable {
            stabilityCount += 1
        } else {
            stabilityLabel = label
            stabilityCount = isStable ? 1 : 0
            resetFallbackTimer()
        }

        let progress = min(Double(stabilityCount) / Double(stabilityThreshold), 1.0)

        if stabilityCount >= stabilityThreshold {
            scanState   = .locked
            lockedImage = capturedImage
            cancelFallbackTimer()
            fire(label: label, confidence: confidence, image: capturedImage)
        } else if isStable, stabilityCount > 0 {
            scanState = .locking(progress)
        } else {
            scanState = .searching
        }
    }

    private func fire(label: String, confidence: Float, image: UIImage?) {
        cooldownLabel = label
        scanState     = .processing
        let conf      = Double(confidence)
        let result    = ClassificationResult(
            label:      label,
            confidence: conf,
            allResults: [ClassificationCandidate(label: label, confidence: conf)]
        )
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onAutoTrigger?(result, image)
    }

    // MARK: – Fallback timer

    private func resetFallbackTimer() {
        cancelFallbackTimer()
        showFallbackButton = false
        fallbackTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(3_500_000_000))
            guard let self, !Task.isCancelled else { return }
            self.showFallbackButton = true
        }
    }

    private func cancelFallbackTimer() {
        fallbackTask?.cancel()
        fallbackTask = nil
    }

    // MARK: – Activation

    /// Call once from the container view's onAppear.
    /// Starts the fallback-button countdown immediately so it appears even if the
    /// classifier is slow to produce its first result (e.g. model load delay).
    func activate() {
        guard fallbackTask == nil else { return }
        resetFallbackTimer()
    }

    // MARK: – Manual fallback tap

    /// Called when the user taps "Tap to scan now" before auto-lock.
    func tapToScanNow() {
        guard scanState != .processing else { return }
        let label      = currentLabel.isEmpty ? "other_trash" : currentLabel
        let confidence = max(currentConfidence, 0.5)
        fire(label: label, confidence: confidence, image: lockedImage)
    }

    // MARK: – Reset

    /// Resets for the next scan after ResultView is dismissed.
    func reset() {
        scanState          = .searching
        currentLabel       = ""
        currentConfidence  = 0
        currentCategory    = .other
        showFallbackButton = false
        stabilityLabel     = ""
        stabilityCount     = 0
        cooldownLabel      = nil
        lockedImage        = nil
        cancelFallbackTimer()
    }
}
