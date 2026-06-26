import SwiftUI

// MARK: – Pipeline stage

/// Represents each stage of the two-agent visual pipeline.
enum PipelineStage: Equatable {
    case idle
    case detecting
    case interpreting
    case advising
    case complete
    case error(String)

    static func == (lhs: PipelineStage, rhs: PipelineStage) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.detecting, .detecting),
             (.interpreting, .interpreting), (.advising, .advising),
             (.complete, .complete):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: – App errors

/// Typed errors surfaced through the UI.
enum AppError: Error, LocalizedError {
    case modelNotAvailable
    case invalidImage
    case classificationFailed(String)
    case noResultsFound
    case agentFailed(String)
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:           return "Classifier model not loaded. Add BinWise_Training 1.mlmodel to the project."
        case .invalidImage:                return "Could not process the selected image."
        case .classificationFailed(let m): return "Detection failed: \(m)"
        case .noResultsFound:              return "The model returned no results. Try a clearer photo."
        case .agentFailed(let m):          return "Agent error: \(m)"
        case .saveFailed:                  return "Could not save the record."
        }
    }
}

// MARK: – ViewModel

/// Drives the complete scan → detect → interpret → advise → display pipeline.
/// Used by both the photo picker flow and the live camera flow.
@MainActor
final class ScanViewModel: ObservableObject {
    @Published var stage: PipelineStage = .idle
    @Published var capturedImage: UIImage?
    @Published var classificationResult: ClassificationResult?
    @Published var assessment: AgentAssessment?
    @Published var guidance: String?
    @Published var lowConfidence: Bool = false
    /// Top candidates shown in the low-confidence UI path.
    @Published var candidates: [ClassificationCandidate] = []
    /// Optional clarification text supplied by the user before the Advisor runs.
    @Published var userClarification: String = ""
    /// Safety advisory produced by WasteSafetyPolicy; available after interpreting stage.
    @Published private(set) var safetyAdvisory: WasteSafetyPolicy.SafetyAdvisory?
    /// How this scan was initiated — written into ScanRecord when the user saves.
    var scanSource: ScanRecord.ScanSource = .photo

    private let classifier = ClassifierService()
    private let claude     = ClaudeService()
    private let policy     = WasteSafetyPolicy()

    // MARK: – Public interface (photo flow)

    /// Call after the user picks a photo. Runs Vision/CoreML then both agents.
    func process(image: UIImage) {
        capturedImage = image
        scanSource    = .photo
        Task { await runPipeline(image: image) }
    }

    // MARK: – Public interface (live camera flow)

    /// Called by LiveScanViewModel after auto-lock.
    /// Skips Vision detection (already done live) and runs both agents directly.
    func processWithKnownResult(_ result: ClassificationResult, image: UIImage?) {
        capturedImage        = image
        classificationResult = result
        lowConfidence        = result.isLowConfidence
        candidates           = result.isLowConfidence ? Array(result.allResults.prefix(3)) : []
        scanSource           = .liveCamera
        Task { await runAgentPipeline(result: result) }
    }

    // MARK: – Public interface (barcode / OCR flows)

    /// Called by barcode and OCR flows.
    /// Skips Vision detection and the Interpreter Agent — calls the Advisor directly
    /// with a pre-built `AgentAssessment` derived from Open Food Facts or OCR output.
    func processWithAssessment(_ assessment: AgentAssessment, image: UIImage?) {
        reset()
        capturedImage    = image
        self.assessment  = assessment
        scanSource       = .barcode
        stage            = .advising
        Task {
            let advisorText: String
            do {
                advisorText = try await claude.advise(
                    assessment: assessment,
                    userClarification: nil
                )
            } catch {
                stage = .error(error.localizedDescription)
                return
            }
            guidance = advisorText
            stage    = .complete
        }
    }

    // MARK: – Reset

    /// Resets all state so the view model can be reused for a new scan.
    func reset() {
        stage                = .idle
        capturedImage        = nil
        classificationResult = nil
        assessment           = nil
        guidance             = nil
        safetyAdvisory       = nil
        lowConfidence        = false
        candidates           = []
        userClarification    = ""
        scanSource           = .photo
    }

    // MARK: – Private pipeline

    private func runPipeline(image: UIImage) async {
        stage = .detecting
        let result: ClassificationResult
        do {
            result = try await classifier.classify(image: image)
        } catch {
            stage = .error(error.localizedDescription)
            return
        }
        classificationResult = result
        lowConfidence = result.isLowConfidence
        candidates = result.isLowConfidence ? Array(result.allResults.prefix(3)) : []
        await runAgentPipeline(result: result)
    }

    /// Runs Interpreter → Safety policy → Advisor. Shared by photo and live camera flows.
    private func runAgentPipeline(result: ClassificationResult) async {
        stage = .interpreting
        let agentAssessment: AgentAssessment
        do {
            agentAssessment = try await claude.interpret(result: result)
        } catch {
            stage = .error(error.localizedDescription)
            return
        }
        assessment = agentAssessment

        // Evaluate safety policy using the interpreter's resolved category
        let resolvedCat = WasteCategory(rawValue: agentAssessment.category)
            ?? MappingService.category(for: result.label)
        let advisory = policy.evaluate(category: resolvedCat, objectLabel: result.label)
        safetyAdvisory = advisory

        stage = .advising
        let advisorText: String
        do {
            advisorText = try await claude.advise(
                assessment: agentAssessment,
                userClarification: userClarification.isEmpty ? nil : userClarification,
                safetyAdvisory: advisory
            )
        } catch {
            stage = .error(error.localizedDescription)
            return
        }
        guidance = advisorText
        stage    = .complete
    }
}
